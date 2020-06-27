defmodule PolicrMini.Bot.StartCommander do
  @moduledoc """
  `/start` 命令的响应模块。
  与其它命令不同，`/start` 命令不需要完整匹配，以 `/start` 开头的**私聊文本消息**都能进入处理函数。
  这是因为 `/start` 是当前设计中唯一一个需要携带参数的命令。
  """
  use PolicrMini.Bot.Commander, :start

  require Logger

  alias PolicrMini.{VerificationBusiness, SchemeBusiness, MessageSnapshotBusiness}
  alias PolicrMini.Schema.Verification
  alias PolicrMini.Bot.{ArithmeticCaptcha, FallbackCaptcha, ImageCaptcha}

  @fallback_captcha_module FallbackCaptcha

  @captchas_maping [
    image: ImageCaptcha,
    arithmetic: ArithmeticCaptcha,
    # 当前的备用验证就是主动验证
    initiative: FallbackCaptcha
  ]

  @doc """
  重写后的 `match?/1` 函数，以 `/start` 开始即匹配。
  """
  @impl true
  def match?(text), do: text |> String.starts_with?(@command)

  @doc """
  群组消息，忽略。
  """
  @impl true
  def handle(%{chat: %{type: "group"}}, state), do: {:ignored, state}

  @doc """
  群组（超级群）消息，忽略。
  """
  @impl true
  def handle(%{chat: %{type: "supergroup"}}, state), do: {:ignored, state}

  @doc """
  响应命令。
  如果命令没有携带参数，则发送包含链接的项目介绍。否则将参数整体传递给 `dispatch/1` 函数进一步拆分和分发。
  """
  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}, text: text} = message

    splited_text = text |> String.split(" ")

    if length(splited_text) == 2 do
      splited_text |> List.last() |> dispatch(message)
    else
      send_message(chat_id, t("start.response"))
    end

    {:ok, state}
  end

  @doc """
  分发命令参数。
  以 `_` 分割成更多参数，转发给 `handle_args/1` 函数处理。
  """
  def dispatch(arg, message), do: arg |> String.split("_") |> handle_args(message)

  @spec handle_args([String.t(), ...], Telegex.Model.Message.t()) ::
          :ok | {:error, Telegex.Model.errors()}
  @doc """
  处理 v1 版本的验证参数。
  """
  def handle_args(["verification", "v1", target_chat_id], %{chat: %{id: from_user_id}} = message) do
    target_chat_id = target_chat_id |> String.to_integer()

    if verification = VerificationBusiness.find_unity_waiting(target_chat_id, from_user_id) do
      # 读取验证方案（当前的实现没有实际根据方案数据动态决定什么）
      with {:ok, scheme} <- SchemeBusiness.fetch(target_chat_id),
           # 发送验证消息
           {:ok, {verification_message, markup, captcha_data}} <-
             send_verification_message(verification, scheme, target_chat_id, from_user_id),
           # 创建消息快照
           {:ok, message_snapshot} <-
             MessageSnapshotBusiness.create(%{
               chat_id: target_chat_id,
               message_id: verification_message.message_id,
               from_user_id: from_user_id,
               from_user_name: fullname(message.from),
               date: verification_message.date,
               text: verification_message.text,
               markup_body: Jason.encode!(markup, pretty: false),
               caption: verification_message.caption,
               photo_id: get_photo_id(verification_message)
             }),
           # 更新验证记录：关联消息快照、存储正确答案
           {:ok, _} <-
             verification
             |> VerificationBusiness.update(%{
               message_snapshot_id: message_snapshot.id,
               indices: captcha_data.correct_indices
             }) do
      else
        e ->
          Logger.error(
            "An error occurred while creating the verification message. Details: #{inspect(e)}"
          )

          send_message(from_user_id, t("errors.unknown"))
      end
    else
      send_message(from_user_id, t("errors.verification_no_wating"))
    end
  end

  @doc """
  响应未知参数。
  """
  def handle_args(_, message) do
    %{chat: %{id: chat_id}} = message

    send_message(chat_id, t("errors.dont_understand"))
  end

  @spec send_verification_message(
          Verification.t(),
          Scheme.t(),
          integer(),
          integer()
        ) ::
          {:error, Telegex.Model.errors()}
          | {:ok,
             {Telegex.Model.Message.t(), Telegex.Model.InlineKeyboardMarkup.t(), Captcha.Data.t()}}
  @doc """
  发送验证消息
  """
  def send_verification_message(verification, scheme, chat_id, user_id) do
    mode = scheme.verification_mode || default!(:vmode)

    cmodule = @captchas_maping[mode] || @fallback_captcha_module

    # 获取验证数据。
    # 如果构造验证数据的过程中出现异常，会使用备用验证模块。
    # 所以最终采用的验证模块也需要重新返回。
    {cmodule, cdata} =
      try do
        {cmodule, cmodule.make!()}
      rescue
        e ->
          Logger.error(
            "An error occurred in the verification data generation of group `#{chat_id}`, fallback to alternatives. Details: #{
              inspect(e)
            }"
          )

          {@fallback_captcha_module, @fallback_captcha_module.make!()}
      end

    markup = PolicrMini.Bot.Captcha.build_markup(cdata.candidates, verification.id)

    text =
      t("verification.template", %{
        question: cdata.question,
        seconds: time_left(verification)
      })

    send_fun =
      case cmodule do
        ImageCaptcha ->
          fn -> send_photo(user_id, cdata.photo, caption: text, reply_markup: markup) end

        ArithmeticCaptcha ->
          fn -> send_message(user_id, text, reply_markup: markup) end

        FallbackCaptcha ->
          fn -> send_message(user_id, text, reply_markup: markup) end

        _ ->
          fn -> send_message(user_id, text, reply_markup: markup) end
      end

    # 发送验证消息
    case send_fun.() do
      {:ok, sended_message} ->
        {:ok, {sended_message, markup, cdata}}

      e ->
        e
    end
  end

  @doc """
  根据验证记录计算剩余时间
  """
  @spec time_left(Verification.t()) :: integer()
  def time_left(%Verification{seconds: seconds, inserted_at: inserted_at}) do
    seconds - DateTime.diff(DateTime.utc_now(), inserted_at)
  end

  def get_photo_id(%Telegex.Model.Message{photo: [%Telegex.Model.PhotoSize{file_id: file_id} | _]}),
      do: file_id

  def get_photo_id(%Telegex.Model.Message{photo: []}), do: nil
  def get_photo_id(%Telegex.Model.Message{photo: nil}), do: nil
end
