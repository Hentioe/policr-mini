defmodule PolicrMini.Chats.Scheme do
  @moduledoc """
  方案模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.EctoEnums.{
    VerificationModeEnum,
    KillingMethodEnum,
    MentionText,
    ServiceMessage
  }

  @required_fields ~w(chat_id)a
  @optional_fields ~w(
                      verification_mode
                      seconds
                      timeout_killing_method
                      wrong_killing_method
                      mention_text
                      image_answers_count
                      service_message_cleanup
                      delay_unban_secs
                    )a

  schema "schemes" do
    # 群组 ID
    field :chat_id, :integer
    # 验证模式
    field :verification_mode, VerificationModeEnum
    # 验证时长
    field :seconds, :integer
    # 超时结果的击杀方法
    field :timeout_killing_method, KillingMethodEnum
    # 错误结果的击杀方法
    field :wrong_killing_method, KillingMethodEnum
    # 提及文本
    field :mention_text, MentionText
    # 图片验证的答案个数
    field :image_answers_count, :integer
    # 清理的服务消息列表
    field :service_message_cleanup, {:array, ServiceMessage}
    # 延迟解封时间（秒）
    field :delay_unban_secs, :integer

    timestamps()
  end

  # 用户输入的图片答案个数必须大于或等于 3，且小于或等于 5
  @users_image_answers_count_validate [greater_than_or_equal_to: 3, less_than_or_equal_to: 5]
  # 用户输入的延迟解封时长必须大于或等于 45 秒，且小于或等于 18000 秒（5 个小时）。
  @users_delay_unban_secs_validate [greater_than_or_equal_to: 45, less_than_or_equal_to: 18000]

  # 针对默认 scheme 去掉一些约束检查
  def changeset(%{chat_id: 0} = struct, attrs)
      when is_struct(struct, __MODULE__) and is_map(attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:chat_id)
    |> validate_number(:delay_unban_secs, greater_than_or_equal_to: 45)
  end

  def changeset(struct, attrs) when is_struct(struct, __MODULE__) and is_map(attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:chat_id)
    |> validate_number(:image_answers_count, @users_image_answers_count_validate)
    |> validate_number(:delay_unban_secs, @users_delay_unban_secs_validate)
  end
end
