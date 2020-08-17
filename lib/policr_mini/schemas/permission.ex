defmodule PolicrMini.Schemas.Permission do
  @moduledoc """
  权限模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.Schemas.{Chat, User}

  @required_fields ~w(chat_id user_id tg_is_owner)a
  @optional_fields ~w(tg_can_restrict_members tg_can_promote_members readable writable customized)a

  schema "permissions" do
    belongs_to :chat, Chat
    belongs_to :user, User

    field :tg_is_owner, :boolean
    field :tg_can_restrict_members, :boolean
    field :tg_can_promote_members, :boolean
    field :readable, :boolean
    field :writable, :boolean
    field :customized, :boolean

    timestamps()
  end

  @type t :: map()

  def changeset(%__MODULE__{} = permission, attrs) when is_map(attrs) do
    permission
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:chat_id, :user_id])
    |> assoc_constraint(:chat)
    |> assoc_constraint(:user)
  end
end
