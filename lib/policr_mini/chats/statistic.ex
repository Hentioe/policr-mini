defmodule PolicrMini.Chats.Statistic do
  @moduledoc """
  统计模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.Instances.Chat
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

  def changeset(module, attrs) when is_struct(module, __MODULE__) and is_map(attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:chat)
  end

  @day_seconds 3600 * 24
  @midnight ~T[00:00:00]

  def today_datetimes do
    begin_at = DateTime.new!(Date.utc_today(), @midnight, "Etc/UTC")
    end_at = DateTime.add(begin_at, @day_seconds - 1, :second)

    {begin_at, end_at}
  end

  def yesterday_datetimes do
    today_date = Date.utc_today()
    yesterday_date = Date.add(today_date, -1)

    begin_at = DateTime.new!(yesterday_date, @midnight, "Etc/UTC")
    end_at = DateTime.add(begin_at, @day_seconds - 1, :second)

    {begin_at, end_at}
  end
end
