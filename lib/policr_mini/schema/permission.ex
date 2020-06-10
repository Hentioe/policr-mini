defmodule PolicrMini.Schema.Permission do
  use PolicrMini.Schema

  alias PolicrMini.Schema.{Chat, User}

  @required_fields ~w(chat_id user_id tg_is_owner tg_can_promote_members tg_can_restrict_members)a
  @optional_fields ~w(readable writable)a

  schema "permissions" do
    belongs_to :chat, Chat
    belongs_to :user, User

    field :tg_is_owner, :boolean
    field :tg_can_promote_members, :boolean
    field :tg_can_restrict_members, :boolean
    field :readable, :boolean
    field :writable, :boolean

    timestamps()
  end

  def changeset(%__MODULE__{} = permission, attrs) when is_map(attrs) do
    permission
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:chat_id, :user_id])
  end
end
