defmodule PolicrMini.Schema.Verification do
  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.{VerificationEntranceEnum, VerificationStatusEnum}
  alias PolicrMini.Schema.{Chat, MessageSnapshot}

  @required_fields ~w(chat_id target_user_id entrance seconds status)a
  @optional_fields ~w(message_snapshot_id target_user_name message_id indices chosen)a

  schema "verifications" do
    belongs_to :chat, Chat
    belongs_to :message_snapshot, MessageSnapshot

    field :target_user_id, :integer
    field :target_user_name, :string
    field :entrance, VerificationEntranceEnum
    field :message_id, :integer
    field :indices, {:array, :integer}
    field :seconds, :integer
    field :status, VerificationStatusEnum
    field :chosen, :integer

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
