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
    %PolicrMini.Schema.CustomKit{
      title: "猫吃老鼠吗？",
      answers: ["+吃", "-不吃"]
    }
  end

  def build(:scheme) do
    %PolicrMini.Chats.Scheme{
      verification_mode: 0,
      verification_entrance: 0,
      verification_occasion: 0,
      seconds: 80,
      timeout_killing_method: :kick,
      wrong_killing_method: :ban,
      is_highlighted: true,
      service_message_cleanup: [:joined]
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
    %PolicrMini.Schema.Operation{
      verification_id: 10_000,
      action: :kick,
      role: :system
    }
  end

  def build(:statistic) do
    utc_now_date = Date.utc_today()

    begin_at = DateTime.new!(utc_now_date, ~T[00:00:00], "Etc/UTC")
    end_at = DateTime.add(begin_at, 3600 * 24 - 1, :second)

    %PolicrMini.Schema.Statistic{
      verifications_count: 0,
      languages_top: %{},
      begin_at: begin_at,
      end_at: end_at,
      verification_status: :other
    }
  end

  def build(:third_party) do
    %PolicrMini.Schema.ThirdParty{
      name: "开发实例",
      bot_username: "policr_mini_dev_bot",
      homepage: "https://mini-dev.telestd.me",
      running_days: 1,
      version: "0.0.1-rc.0",
      is_forked: false
    }
  end

  def build(:term) do
    %PolicrMini.Instances.Term{
      id: 1_234_567_890,
      content: "服务条款内容。"
    }
  end

  def build(:sponsor) do
    %PolicrMini.Instances.Sponsor{
      title: "喵小姐",
      avatar: "/uploaded/meow.jpg",
      homepage: "https://meow.com",
      introduction: "欢迎来我的主页逛逛",
      contact: "@miss_meow",
      uuid: "xxxx-xxxx-xxxx-xxxx"
    }
  end

  def build(:sponsorship_history) do
    %PolicrMini.Instances.SponsorshipHistory{
      expected_to: "请作者喝一杯无糖可乐",
      amount: 15,
      has_reached: false,
      reached_at: DateTime.truncate(DateTime.utc_now(), :second),
      hidden: false
    }
  end

  def build(:sponsorship_addresses) do
    %PolicrMini.Instances.SponsorshipAddress{
      name: "USDT (TRC20)",
      description: "如美元般稳定的加密货币 USDT 的转账地址，仅限 TRC20 网络。",
      text: "****************************",
      image: "usdt-trc20-qrcode.jpg"
    }
  end

  def build(factory_name, attrs) when is_atom(factory_name) and is_list(attrs) do
    factory_name |> build() |> struct(attrs)
  end
end
