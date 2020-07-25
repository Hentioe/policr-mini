defmodule PolicrMini.Schemas.CustomKit do
  @moduledoc """
  自定义套件模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.Schemas.Chat

  @required_fields ~w(chat_id title answers)a
  @optional_fields ~w(photos)a

  schema "custom_kits" do
    belongs_to :chat, Chat

    field :title, :string
    field :answers, {:array, :string}
    field :photos, {:array, :string}

    timestamps()
  end

  @type t :: Ecto.Schemas.t()

  def changeset(%__MODULE__{} = custom_kit, attrs) when is_map(attrs) do
    custom_kit
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:chat)
  end
end
