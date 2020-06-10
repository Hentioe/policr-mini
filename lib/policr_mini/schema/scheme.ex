defmodule PolicrMini.Schema.Scheme do
  use PolicrMini.Schema

  alias PolicrMini.Schema.Chat

  alias PolicrMini.EctoEnums.{
    VerificationModeEnum,
    KillingMethodEnum,
    VerificationEntranceEnum,
    VerificationOccasionEnum
  }

  @required_fields ~w(chat_id)a
  @optional_fields ~w(verification_mode verification_entrance verification_occasion seconds killing_method is_highlighted)a

  schema "schemes" do
    belongs_to :chat, Chat

    field :verification_mode, VerificationModeEnum
    field :verification_entrance, VerificationEntranceEnum
    field :verification_occasion, VerificationOccasionEnum
    field :seconds, :integer
    field :killing_method, KillingMethodEnum
    field :is_highlighted, :boolean

    timestamps()
  end

  def changeset(%__MODULE__{} = scheme, attrs) when is_map(attrs) do
    scheme
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
