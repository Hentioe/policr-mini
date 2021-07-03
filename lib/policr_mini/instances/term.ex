defmodule PolicrMini.Instances.Term do
  @moduledoc """
  服务条款模式。
  """

  use PolicrMini.Schema

  @required_fields ~w(id)a
  @optional_fields ~w(content)a

  @primary_key {:id, :integer, autogenerate: false}
  schema "terms" do
    field :content, :string

    timestamps()
  end

  def changeset(module, attrs) when is_struct(module, __MODULE__) and is_map(attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
