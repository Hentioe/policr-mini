defmodule PolicrMini.Factory do
  @moduledoc false

  def build(:user) do
    %PolicrMini.Schema.User{
      id: 123_456_789,
      first_name: "小",
      last_name: "明",
      username: "xiaoming",
      token_ver: 0
    }
  end

  def build(:chat) do
    %PolicrMini.Instances.Chat{
      id: 1_234_567_890,
      type: "supergroup",
      title: "Elixir 编程语言",
      small_photo_id: "KdIlCrIKzd",
      big_photo_id: "OkdiOAdjioI",
      username: "elixir_cn",
      description: "Elixir 编程语言中文交流群",
      is_take_over: true
    }
  end

  def build(:permission) do
    %PolicrMini.Schema.Permission{
      tg_is_owner: true,
      tg_can_promote_members: true,
      tg_can_restrict_members: true,
      readable: true,
      writable: true
    }
  end

  def build(:custom_kit) do
    %PolicrMini.Chats.CustomKit{
      title: "猫吃老鼠吗？",
      answers: ["+吃", "-不吃"]
    }
  end

  def build(:scheme) do
    %PolicrMini.Chats.Scheme{
      verification_mode: 0,
      seconds: 80,
      timeout_killing_method: :kick,
      wrong_killing_method: :ban,
      image_answers_count: 4,
      service_message_cleanup: [:joined],
      delay_unban_secs: 60
    }
  end

  def build(:verification) do
    %PolicrMini.Chats.Verification{
      target_user_id: 491_837_624,
      target_user_name: "小明",
      message_id: 1234,
      indices: [1, 3],
      seconds: 60,
      status: 0,
      source: :joined
    }
  end

  def build(:operation) do
    %PolicrMini.Chats.Operation{
      chat_id: -100_123_456_789,
      verification_id: 10_000,
      action: :kick,
      role: :system
    }
  end

  def build(:term) do
    %PolicrMini.Instances.Term{
      id: 1_234_567_890,
      content: "服务条款内容。"
    }
  end

  def build(factory_name, attrs) when is_atom(factory_name) and is_list(attrs) do
    factory_name |> build() |> struct(attrs)
  end
end
