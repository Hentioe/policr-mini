defmodule PolicrMini.Schema.ThirdParty do
  @moduledoc """
  统计模型。
  """

  use PolicrMini.Schema

  @required_fields ~w(name bot_username homepage running_days version is_forked)a
  @optional_fields ~w(bot_avatar description hardware)a

  schema "third_parties" do
    field :name, :string
    field :bot_username, :string
    field :bot_avatar, :string
    field :homepage, :string
    field :description, :string
    field :hardware, :string
    field :running_days, :integer, default: 1
    field :version, :string
    field :is_forked, :boolean

    timestamps()
  end

  @type t :: Ecto.Schema.t()

  def changeset(module, attrs) when is_struct(module, __MODULE__) and is_map(attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
