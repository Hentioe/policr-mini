defmodule PolicrMini.Schema.Verification do
  @moduledoc """
  验证模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.{VerificationStatusEnum, VerificationSource}
  alias PolicrMini.Instances.Chat
  alias PolicrMini.Schema.MessageSnapshot

  @required_fields ~w(chat_id target_user_id seconds status source)a
  @optional_fields ~w(message_snapshot_id target_user_name target_user_language_code message_id indices chosen)a

  schema "verifications" do
    belongs_to :chat, Chat
    belongs_to :message_snapshot, MessageSnapshot

    field :target_user_id, :integer
    field :target_user_name, :string
    field :target_user_language_code, :string
    field :message_id, :integer
    field :indices, {:array, :integer}
    field :seconds, :integer
    field :status, VerificationStatusEnum
    field :chosen, :integer
    field :source, VerificationSource

    timestamps()
  end

  def changeset(%__MODULE__{} = verification, attrs) when is_map(attrs) do
    verification
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:chat)
    |> assoc_constraint(:message_snapshot)
  end
end
