defmodule PolicrMini.Instances.SponsorshipAddress do
  @moduledoc """
  赞助地址。
  """

  use PolicrMini.Schema

  @required_fields ~w(name)a
  @optional_fields ~w(description text image)a

  schema "sponsorship_addresses" do
    field :name, :string
    field :description, :string
    field :text, :string
    field :image, :string

    timestamps()
  end

  def changeset(module, attrs) when is_struct(module, __MODULE__) and is_map(attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
