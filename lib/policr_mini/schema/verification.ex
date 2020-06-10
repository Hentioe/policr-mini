defmodule PolicrMini.Schema.Verification do
  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.VerificationStatusEnum
  alias PolicrMini.Schema.{Chat, MessageSnapshot}

  @required_fields ~w(chat_id message_snapshot_id message_id indices seconds status)a
  @optional_fields ~w(chosen)a

  schema "verifications" do
    belongs_to :chat, Chat
    belongs_to :message_snapshot, MessageSnapshot

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
  end
end
