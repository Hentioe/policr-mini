defmodule PolicrMini.Schema.Scheme do
  @moduledoc """
  方案模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.Schema.Chat

  alias PolicrMini.EctoEnums.{
    VerificationModeEnum,
    KillingMethodEnum,
    VerificationEntranceEnum,
    VerificationOccasionEnum
  }

  @required_fields ~w(chat_id)a
  @optional_fields ~w(verification_mode verification_entrance verification_occasion seconds timeout_killing_method wrong_killing_method is_highlighted)a

  schema "schemes" do
    belongs_to :chat, Chat

    field :verification_mode, VerificationModeEnum
    field :verification_entrance, VerificationEntranceEnum
    field :verification_occasion, VerificationOccasionEnum
    field :seconds, :integer
    field :timeout_killing_method, KillingMethodEnum
    field :wrong_killing_method, KillingMethodEnum
    field :is_highlighted, :boolean

    timestamps()
  end

  @type t :: map()

  def changeset(%__MODULE__{} = scheme, attrs) when is_map(attrs) do
    scheme
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:chat)
    |> unique_constraint(:chat_id)
  end
end
