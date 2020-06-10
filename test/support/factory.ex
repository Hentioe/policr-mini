defmodule PolicrMini.Factory do
  def build(:user) do
    %PolicrMini.Schema.User{
      id: 123_456_789,
      first_name: "小",
      last_name: "明",
      username: "xiaoming"
    }
  end

  def build(:chat) do
    %PolicrMini.Schema.Chat{
      id: 123_456_789_0,
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
    %PolicrMini.Schema.CustomKit{
      title: "猫吃老鼠吗？",
      answer_body: "+吃 -不吃"
    }
  end

  def build(:scheme) do
    %PolicrMini.Schema.Scheme{
      verification_mode: 0,
      verification_entrance: 0,
      verification_occasion: 0,
      seconds: 80,
      killing_method: 0,
      is_highlighted: true
    }
  end

  def build(:message_snapshot) do
    %PolicrMini.Schema.MessageSnapshot{
      message_id: 1234,
      from_user_id: 123_456_789,
      from_user_name: "小新",
      date: 1_591_654_677,
      text: "请回答问题「1 + 1 = ?」。您有 20 秒的时间通过此验证，超时将从群组【Elixir 中文交流】中封禁。",
      markup_body: "[3](101:1) [2](101:2)"
    }
  end

  def build(:verification) do
    %PolicrMini.Schema.Verification{
      message_id: 1234,
      indices: [1, 3],
      seconds: 60,
      status: 0
    }
  end

  def build(factory_name, attrs) when is_atom(factory_name) and is_list(attrs) do
    factory_name |> build() |> struct(attrs)
  end
end
