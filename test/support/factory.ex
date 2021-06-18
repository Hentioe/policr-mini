defmodule PolicrMini.Factory do
  @moduledoc false

  def build(:user) do
    %PolicrMini.Schemas.User{
      id: 123_456_789,
      first_name: "小",
      last_name: "明",
      username: "xiaoming",
      token_ver: 0
    }
  end

  def build(:chat) do
    %PolicrMini.Schemas.Chat{
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
    %PolicrMini.Schemas.Permission{
      tg_is_owner: true,
      tg_can_promote_members: true,
      tg_can_restrict_members: true,
      readable: true,
      writable: true
    }
  end

  def build(:custom_kit) do
    %PolicrMini.Schemas.CustomKit{
      title: "猫吃老鼠吗？",
      answers: ["+吃", "-不吃"]
    }
  end

  def build(:scheme) do
    %PolicrMini.Schemas.Scheme{
      verification_mode: 0,
      verification_entrance: 0,
      verification_occasion: 0,
      seconds: 80,
      timeout_killing_method: :kick,
      wrong_killing_method: :ban,
      is_highlighted: true
    }
  end

  def build(:message_snapshot) do
    %PolicrMini.Schemas.MessageSnapshot{
      message_id: 1234,
      from_user_id: 123_456_789,
      from_user_name: "小新",
      date: 1_591_654_677,
      text: "请回答问题「1 + 1 = ?」。您有 20 秒的时间通过此验证，超时将从群组【Elixir 中文交流】中封禁。",
      markup_body: "[3](101:1) [2](101:2)"
    }
  end

  def build(:verification) do
    %PolicrMini.Schemas.Verification{
      target_user_id: 491_837_624,
      target_user_name: "小明",
      entrance: 0,
      message_id: 1234,
      indices: [1, 3],
      seconds: 60,
      status: 0
    }
  end

  def build(:operation) do
    %PolicrMini.Schemas.Operation{
      verification_id: 10_000,
      action: :kick,
      role: :system
    }
  end

  def build(:statistic) do
    %PolicrMini.Schemas.Statistic{
      verifications_count: 0,
      languages_top: %{},
      begin_at: DateTime.utc_now(),
      end_at: DateTime.utc_now(),
      verification_status: :other
    }
  end

  def build(factory_name, attrs) when is_atom(factory_name) and is_list(attrs) do
    factory_name |> build() |> struct(attrs)
  end
end
