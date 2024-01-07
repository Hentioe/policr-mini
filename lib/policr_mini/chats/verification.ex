defmodule PolicrMini.Chats.Verification do
  @moduledoc """
  验证模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.{VerificationStatusEnum, VerificationSource}
  alias PolicrMini.Instances.Chat

  @required_fields ~w(chat_id target_user_id seconds status source)a
  @optional_fields ~w(target_user_name target_user_language_code message_id indices chosen send_times)a

  schema "verifications" do
    belongs_to :chat, Chat

    field :target_user_id, :integer
    field :target_user_name, :string
    field :target_user_language_code, :string
    field :message_id, :integer
    field :indices, {:array, :integer}
    field :seconds, :integer
    field :status, VerificationStatusEnum
    field :chosen, :integer
    field :source, VerificationSource
    field :send_times, :integer, default: 0

    timestamps()
  end

  def changeset(%__MODULE__{} = verification, attrs) when is_map(attrs) do
    verification
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:chat)
  end
end
