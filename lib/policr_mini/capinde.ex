defmodule PolicrMini.Capinde do
  @moduledoc false

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

  @content_type_header {"Content-Type", "application/json"}

  def generate(input) when is_struct(input, Input) do
    :post
    |> Finch.build(endpoint(), [@content_type_header], JSON.encode!(input))
    |> Finch.request(__MODULE__)
    |> case_resp()
  end

  defp case_resp({:ok, resp}) when resp.status == 200 do
    {:ok, resp.body |> JSON.decode!() |> Generated.from()}
  end

  defp case_resp({:ok, resp}) do
    %{"message" => message} = JSON.decode!(resp.body)

    {:error, %Error{message: message}}
  end

  defp case_resp({:error, reason}) do
    {:error, reason}
  end

  defp endpoint do
    base_url = Application.get_env(:policr_mini, __MODULE__, [])[:base_url]

    "#{base_url}/api/generate"
  end
end
