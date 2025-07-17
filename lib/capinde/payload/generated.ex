defmodule Capinde.Payload.Generated do
  @moduledoc false

  use TypedStruct

  @type i18n_name :: %{String.t() => String.t()}

  defmodule GridPayload do
    @moduledoc false

    typedstruct do
      field :type, String.t(), default: "grid"
      field :parts, [integer(), ...], enforce: true
      field :subject, Capinde.Payload.Generated.i18n_name(), enforce: true
      field :choices, [[non_neg_integer()], ...], default: []
    end

    def from(%{"parts" => parts, "subject" => subject, "choices" => choices}) do
      %__MODULE__{
        parts: parts,
        subject: subject,
        choices: choices
      }
    end
  end

  defmodule ImagePayload do
    @moduledoc false

    typedstruct do
      field :type, String.t(), default: "image"
      field :name, Capinde.Payload.Generated.i18n_name(), enforce: true
      field :choices, [String.t(), ...], enforce: true
    end

    def from(%{"name" => name, "choices" => choices}) do
      %__MODULE__{
        name: name,
        choices: choices
      }
    end
  end

  defmodule ClassicPayload do
    @moduledoc false

    typedstruct do
      field :type, String.t(), default: "classic"
      field :text, String.t(), enforce: true
      field :choices, [String.t(), ...], default: []
    end

    def from(%{"text" => text, "choices" => choices}) do
      %__MODULE__{
        text: text,
        choices: choices
      }
    end
  end

  @type special_payload :: GridPayload.t() | ImagePayload.t() | ClassicPayload.t()

  typedstruct do
    field :file_name, String.t(), enforce: true
    field :namespace, String.t(), enforce: true
    field :unique_id, String.t(), enforce: true
    field :right_index, non_neg_integer()
    field :special_payload, special_payload(), enforce: true
  end

  defp from_special_payload(%{"type" => "grid"} = payload), do: GridPayload.from(payload)
  defp from_special_payload(%{"type" => "image"} = payload), do: ImagePayload.from(payload)
  defp from_special_payload(%{"type" => "classic"} = payload), do: ClassicPayload.from(payload)

  def from(%{
        "file_name" => file_name,
        "namespace" => namespace,
        "unique_id" => unique_id,
        "right_index" => right_index,
        "special_payload" => special_payload
      }) do
    %__MODULE__{
      file_name: file_name,
      namespace: namespace,
      unique_id: unique_id,
      right_index: right_index,
      special_payload: from_special_payload(special_payload)
    }
  end
end
