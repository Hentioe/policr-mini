defmodule PolicrMini.Schema.Sponsor do
  @moduledoc """
  赞助者模型。
  """

  use PolicrMini.Schema

  @required_fields ~w(contact uuid)a
  @optional_fields ~w(title avatar homepage introduction is_official)a

  schema "sponsors" do
    field :title, :string
    field :avatar, :string
    field :homepage, :string
    field :introduction, :string
    field :contact, :string
    field :uuid, :string
    field :is_official, :boolean

    timestamps()
  end

  @type t :: Ecto.Schema.t()

  def changeset(module, attrs) when is_struct(module, __MODULE__) and is_map(attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
