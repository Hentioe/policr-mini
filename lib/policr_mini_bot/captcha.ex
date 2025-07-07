defmodule PolicrMiniBot.Captcha do
  @moduledoc """
  验证内容生成模块。
  """

  require Logger

  alias PolicrMini.Chats.Scheme
  alias Telegex.Type.{InlineKeyboardButton, InlineKeyboardMarkup}

  alias PolicrMiniBot.{
    ImageCAPTCHA,
    CustomCaptcha,
    ArithmeticCaptcha,
    FallbackCaptcha,
    GridCAPTCHA,
    ClassicCAPTCHA
  }

  @captcha_mapping [
    image: ImageCAPTCHA,
    custom: CustomCaptcha,
    arithmetic: ArithmeticCaptcha,
    grid: GridCAPTCHA,
    classic: ClassicCAPTCHA,
    # 当前的备用验证就是主动验证
    initiative: FallbackCaptcha
  ]

  defmodule Data do
    @moduledoc """
    验证数据
    """

    @typedoc "单个候选内容"
    @type candidate :: String.t() | number()

    use TypedStruct

    typedstruct do
      field :question, String.t()
      field :photo, String.t() | nil
      field :attachment, [String.t()] | nil
      field :candidates, [[candidate(), ...], ...]
      field :markup, InlineKeyboardMarkup.t() | nil
      field :correct_indices, [integer(), ...]
    end
  end

  @data_vsn "v1"

  defmacro __using__(_) do
    quote do
      alias PolicrMiniBot.Captcha

      import Captcha

      @behaviour Captcha
    end
  end

  @doc """
  制造验证数据，提供 `candidates`。
  此函数需要自行实现。
  """
  @callback make!(chat_id :: integer, scheme :: Scheme.t()) :: Data.t()

  @spec build_markup([[Data.candidate()]], integer()) :: InlineKeyboardMarkup.t()
  @doc """
  从候选数据列表中构建 `Telegex.Type.InlineKeyboardMarkup`
  注意，参数 `candidates` 是一个二维数组。参数 `verification_id` 则需要一个已被记录的验证编号。
  此函数的 `candidates` 参数仅作为显示按钮的文本数据，因为回调数组由按钮所在的索引位置自动生成。
  """
  def build_markup(candidates, verification_id)
      when is_integer(verification_id) and is_list(candidates) do
    # 记录每一行的数量
    counts = candidates |> Enum.map(fn candidates -> length(candidates) end)

    # 生成一行按钮
    make_line = fn {candidates, line} ->
      # 获取之前所有行的总数
      count =
        if line == 0,
          do: 0,
          else:
            Enum.reduce(0..(line - 1), 0, fn index, total -> total + Enum.at(counts, index) end)

      candidates
      |> Enum.with_index(1)
      |> Enum.map(fn {text, i} ->
        # 当前行的索引 + 之前行的总数 = 总索引位置
        index = count + i

        %InlineKeyboardButton{
          text: to_string(text),
          callback_data: "ans:#{@data_vsn}:#{index}:#{verification_id}"
        }
      end)
    end

    inline_keyboard =
      candidates
      |> Enum.with_index()
      |> Enum.map(make_line)

    %InlineKeyboardMarkup{inline_keyboard: inline_keyboard}
  end

  def make(captcha_name, chat_id, scheme) do
    module = @captcha_mapping[captcha_name]

    module.make!(chat_id, scheme)
  rescue
    e ->
      Logger.warning(
        "Make captcha data failed: #{inspect(exception: e)}",
        chat_id: chat_id
      )

      FallbackCaptcha.make!(chat_id, scheme)
  end
end
