defmodule PolicrMini.Schemas.Statistic do
  @moduledoc """
  统计模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.Schemas.Chat
  alias PolicrMini.EctoEnums.StatVerificationStatus

  @required_fields ~w(chat_id)a
  @optional_fields ~w(verifications_count languages_top begin_at end_at verification_status)a

  schema "statistics" do
    belongs_to :chat, Chat

    field :verifications_count, :integer, default: 0
    field :languages_top, :map
    field :begin_at, :utc_datetime
    field :end_at, :utc_datetime
    field :verification_status, StatVerificationStatus

    timestamps()
  end

  @type t :: Ecto.Schema.t()

  def changeset(module, attrs) when is_struct(module, __MODULE__) and is_map(attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:chat)
  end
end
