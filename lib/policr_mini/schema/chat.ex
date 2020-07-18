defmodule PolicrMini.Schema.Chat do
  @moduledoc """
  群组（或通用 chat ）模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.ChatTypeEnum

  @required_fields ~w(id type is_take_over)a
  @optional_fields ~w(
                      title small_photo_id big_photo_id username description invite_link
                      tg_can_add_web_page_previews
                      tg_can_change_info
                      tg_can_invite_users
                      tg_can_pin_messages
                      tg_can_send_media_messages
                      tg_can_send_messages
                      tg_can_send_other_messages
                      tg_can_send_polls
                    )a

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
    field :tg_can_add_web_page_previews, :boolean
    field :tg_can_change_info, :boolean
    field :tg_can_invite_users, :boolean
    field :tg_can_pin_messages, :boolean
    field :tg_can_send_media_messages, :boolean
    field :tg_can_send_messages, :boolean
    field :tg_can_send_other_messages, :boolean
    field :tg_can_send_polls, :boolean

    timestamps()
  end

  def changeset(%__MODULE__{} = chat, attrs) when is_map(attrs) do
    chat
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
