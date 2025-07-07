defmodule PolicrMini.Capinde do
  @moduledoc false
  alias Multipart.Part

  defmodule Manifest do
    @moduledoc false

    use TypedStruct

    defmodule Album do
      @moduledoc false

      typedstruct do
        field :id, String.t(), enforce: true
        field :parents, [String.t(), ...], default: []
        field :name, %{String.t() => String.t()}, enforce: true
      end

      def from(%{"id" => id, "parents" => parents, "name" => name}) do
        %__MODULE__{
          id: id,
          parents: parents,
          name: name
        }
      end
    end

    typedstruct do
      field :version, Strintg.t(), enforce: true
      field :datetime, DateTime.t(), enforce: true
      field :include_formats, [String.t(), ...], enforce: true
      field :albums, [Album.t(), ...], default: []
    end

    def from(%{
          "version" => version,
          "datetime" => datetime,
          "include_formats" => include_formats,
          "albums" => albums
        }) do
      {:ok, datetime, _} = DateTime.from_iso8601(datetime)

      %__MODULE__{
        version: version,
        datetime: datetime,
        include_formats: include_formats,
        albums: Enum.map(albums, &Album.from/1)
      }
    end
  end

  defmodule ArchiveInfo do
    @moduledoc false

    use TypedStruct

    typedstruct do
      field :manifest, Manifest.t(), enforce: true
      field :total_images, integer(), enforce: true
    end

    def from(%{"manifest" => manifest, "total_images" => total_images}) do
      %__MODULE__{
        manifest: Manifest.from(manifest),
        total_images: total_images
      }
    end
  end

  defmodule DeployedInfo do
    @moduledoc false

    use TypedStruct

    typedstruct do
      field :manifest, Manifest.t(), enforce: true
      field :total_images, integer(), enforce: true
    end

    def from(%{"manifest" => manifest, "total_images" => total_images}) do
      %__MODULE__{
        manifest: Manifest.from(manifest),
        total_images: total_images
      }
    end
  end

  defmodule Input do
    @moduledoc false

    @derive JSON.Encoder

    use TypedStruct

    typedstruct module: GridParams do
      @derive JSON.Encoder

      field :type, String.t(), default: "grid"
      field :cell_width, integer(), enforce: true
      field :cell_height, integer(), enforce: true
      field :watermark_font_family, String.t(), enforce: true
      field :watermark_font_size, integer()
      field :watermark_font_weight, float()
      field :right_count, integer()
      field :with_choices, boolean()
      field :choices_count, integer()
      field :unordered_right_parts, boolean()
    end

    typedstruct module: ImageParams do
      @derive JSON.Encoder

      field :type, String.t(), default: "image"
      field :dynamic_digest, boolean()
      field :with_choices, boolean()
      field :choices_count, integer()
    end

    @type special_params :: GridParams.t()

    typedstruct do
      field :namespace, String.t(), enforce: true
      field :ttl_secs, integer()
      field :special_params, special_params()
    end
  end

  defmodule Error do
    @moduledoc false

    use TypedStruct

    typedstruct do
      field :message, String.t(), enforce: true
    end
  end

  defmodule Generated do
    @moduledoc false

    use TypedStruct

    defmodule GridPayload do
      @moduledoc false

      typedstruct do
        field :type, String.t(), default: "grid"
        field :right_parts, [integer(), ...], enforce: true
        field :subject, %{String.t() => String.t()}, enforce: true
        field :choices, [[non_neg_integer()], ...], default: []
      end

      def from(%{"right_parts" => right_parts, "subject" => subject, "choices" => choices}) do
        %__MODULE__{
          right_parts: right_parts,
          subject: subject,
          choices: choices
        }
      end
    end

    defmodule ImagePayload do
      @moduledoc false

      typedstruct do
        field :type, String.t(), default: "image"
        field :right_indexes, [non_neg_integer()], enforce: true
        field :choices, [String.t(), ...], enforce: true
      end

      def from(%{"right_indexes" => right_indexes, "choices" => choices}) do
        %__MODULE__{
          right_indexes: right_indexes,
          choices: choices
        }
      end
    end

    @type special_payload :: GridPayload.t() | ImagePayload.t()

    typedstruct do
      field :file_name, String.t(), enforce: true
      field :namespace, String.t(), enforce: true
      field :special_payload, special_payload(), enforce: true
      field :unique_id, String.t(), enforce: true
    end

    defp from_special_payload(%{"type" => "grid"} = payload) do
      GridPayload.from(payload)
    end

    defp from_special_payload(%{"type" => "image"} = payload) do
      ImagePayload.from(payload)
    end

    def from(%{
          "file_name" => file_name,
          "namespace" => namespace,
          "special_payload" => special_payload,
          "unique_id" => unique_id
        }) do
      %__MODULE__{
        file_name: file_name,
        namespace: namespace,
        special_payload: from_special_payload(special_payload),
        unique_id: unique_id
      }
    end
  end

  def deployed do
    call("/provider/deployed", :get, %{}, &DeployedInfo.from/1)
  end

  def uploaded do
    call("/provider/uploaded", :get, %{}, &ArchiveInfo.from/1)
  end

  def upload(archive_path) do
    multipart = Multipart.new()

    multipart =
      Multipart.add_part(
        multipart,
        Part.file_field(archive_path, :archive)
      )

    body_stream = Multipart.body_stream(multipart)
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")
    headers = [{"Content-Type", content_type}, {"Content-Length", to_string(content_length)}]

    Finch.build("POST", "#{endpoint()}/provider/upload", headers, {:stream, body_stream})
    |> Finch.request(__MODULE__)
    |> handle_resp(&ArchiveInfo.from/1)
  end

  def delete_uploaded do
    call("/provider/uploaded", :delete)
  end

  def deploy_uploaded do
    call("/provider/deploy", :put)
  end

  def generate(input) when is_struct(input, Input) do
    call("/generate", :post, input, &Generated.from/1)
  end

  @content_type_header {"Content-Type", "application/json"}

  defp call(path, method, body \\ %{}, cast_fun \\ nil) do
    method
    |> Finch.build("#{endpoint()}#{path}", [@content_type_header], JSON.encode!(body))
    |> Finch.request(__MODULE__)
    |> handle_resp(cast_fun)
  end

  defp handle_resp({:ok, resp}, cast_fun) when resp.status == 200 do
    body = JSON.decode!(resp.body)

    if cast_fun do
      {:ok, cast_fun.(body)}
    else
      {:ok, body}
    end
  end

  defp handle_resp({:ok, resp}, _) do
    %{"message" => message} = JSON.decode!(resp.body)

    {:error, %Error{message: message}}
  end

  defp handle_resp({:error, reason}, _) do
    {:error, reason}
  end

  defp endpoint do
    base_url = Application.get_env(:policr_mini, __MODULE__, [])[:base_url]

    "#{base_url}/api"
  end
end
