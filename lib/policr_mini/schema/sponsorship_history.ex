defmodule PolicrMini.Schema.SponsorshipHistory do
  @moduledoc """
  赞助历史模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.Schema.Sponsor

  @required_fields ~w(amount has_reached)a
  @optional_fields ~w(sponsor_id expected_to reached_at creator)a

  schema "sponsorship_histories" do
    belongs_to :sponsor, Sponsor

    field :expected_to, :string
    field :amount, :integer
    field :has_reached, :boolean
    field :reached_at, :utc_datetime
    field :creator, :integer

    timestamps()
  end

  @type t :: Ecto.Schema.t()

  def changeset(module, attrs) when is_struct(module, __MODULE__) and is_map(attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
