defmodule PolicrMini.Schema.Chat do
  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.ChatTypeEnum

  @required_fields ~w(id type is_take_over)a
  @optional_fields ~w(title small_photo_id big_photo_id username description invite_link)a

  @primary_key {:id, :integer, autogenerate: false}
  schema "chats" do
    field :type, ChatTypeEnum
    field :title, :string
    field :small_photo_id, :string
    field :big_photo_id, :string
    field :username, :string
    field :description, :string
    field :invite_link, :string
    field :is_take_over, :boolean

    timestamps()
  end

  def changeset(%__MODULE__{} = chat, attrs) when is_map(attrs) do
    chat
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
