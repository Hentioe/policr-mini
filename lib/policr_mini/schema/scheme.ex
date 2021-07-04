defmodule PolicrMini.Schema.Scheme do
  @moduledoc """
  方案模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.{
    VerificationModeEnum,
    KillingMethodEnum,
    VerificationEntranceEnum,
    VerificationOccasionEnum,
    MentionText
  }

  @required_fields ~w(chat_id)a
  @optional_fields ~w(
                      verification_mode
                      verification_entrance
                      verification_occasion
                      seconds
                      timeout_killing_method
                      wrong_killing_method
                      is_highlighted
                      mention_text
                      image_answers_count
                    )a

  schema "schemes" do
    field :chat_id, :integer
    field :verification_mode, VerificationModeEnum
    field :verification_entrance, VerificationEntranceEnum
    field :verification_occasion, VerificationOccasionEnum
    field :seconds, :integer
    field :timeout_killing_method, KillingMethodEnum
    field :wrong_killing_method, KillingMethodEnum
    field :is_highlighted, :boolean
    field :mention_text, MentionText
    field :image_answers_count, :integer

    timestamps()
  end

  # 针对默认 scheme 去掉一些约束检查。
  def changeset(%{chat_id: 0} = struct, attrs)
      when is_struct(struct, __MODULE__) and is_map(attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:chat_id)
  end

  def changeset(struct, attrs) when is_struct(struct, __MODULE__) and is_map(attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:chat_id)
  end
end
