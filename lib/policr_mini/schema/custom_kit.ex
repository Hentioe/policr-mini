defmodule PolicrMini.Schema.CustomKit do
  @moduledoc """
  自定义套件模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.Schema.Chat

  @required_fields ~w(chat_id title answer_body)a
  @optional_fields ~w()a

  schema "custom_kits" do
    belongs_to :chat, Chat

    field :title, :string
    field :answer_body, :string

    timestamps()
  end

  def changeset(%__MODULE__{} = custom_kit, attrs) when is_map(attrs) do
    custom_kit
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:chat)
  end
end
