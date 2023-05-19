defmodule PolicrMini.Chats.Operation do
  @moduledoc """
  操作模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.{OperationActionEnum, OperationRoleEnum}
  alias PolicrMini.Chats.Verification
  alias PolicrMini.Instances.Chat

  @required_fields ~w(chat_id verification_id action role)a
  @optional_fields ~w()a

  schema "operations" do
    belongs_to :verification, Verification
    belongs_to :chat, Chat

    field :action, OperationActionEnum
    field :role, OperationRoleEnum

    timestamps()
  end

  def changeset(%__MODULE__{} = operation, attrs) when is_map(attrs) do
    operation
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:verification)
    |> assoc_constraint(:chat)
  end
end
