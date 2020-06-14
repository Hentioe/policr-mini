defmodule PolicrMini.Bot.Captcha do
  @moduledoc """
  验证内容生成模块。
  """

  alias Nadia.Model.{InlineKeyboardButton, InlineKeyboardMarkup}

  defmodule Data do
    defstruct [:question, :candidates, :markup, :correct_indices]

    @type candidate :: String.t() | number()
    @type t :: %__MODULE__{
            question: String.t(),
            candidates: [[candidate(), ...], ...],
            markup: InlineKeyboardMarkup.t() | nil,
            correct_indices: [integer(), ...]
          }
  end

  @data_vsn "v1"

  defmacro __using__(_) do
    quote do
      alias PolicrMini.Bot.Captcha

      import Captcha

      @behaviour Captcha
    end
  end

  @doc """
  制造验证数据，提供 `candidates`。
  此函数需要自行实现。
  """
  @callback make() :: Data.t()

  @spec build_markup([[Data.candidate()]], integer()) :: InlineKeyboardMarkup.t()
  @doc """
  从候选数据列表中构建 `Nadia.Model.InlineKeyboardMarkup`
  注意，参数 `candidates` 是一个二维数组。参数 `verification_id` 则需要一个已被记录的验证编号。
  此函数的 `candidates` 参数仅作为显示按钮的文本数据，因为回调数组由按钮所在的索引位置自动生成。
  """
  def build_markup(candidates, verification_id)
      when is_integer(verification_id) and is_list(candidates) do
    # 记录每一行的数量
    counts = candidates |> Enum.map(fn candidates -> length(candidates) end)

    # 生成一行按钮
    make_line = fn {candidates, line} ->
      # 获取上一行的总数
      count = if line == 0, do: 0, else: counts |> Enum.at(line - 1)

      candidates
      |> Enum.with_index(1)
      |> Enum.map(fn {text, i} ->
        # 当前行的索引 + 上一行的总数 = 总索引位置
        index = count + i

        %InlineKeyboardButton{
          text: to_string(text),
          callback_data: "verification:#{@data_vsn}:#{index}:#{verification_id}"
        }
      end)
    end

    inline_keyboard =
      candidates
      |> Enum.with_index()
      |> Enum.map(make_line)

    %InlineKeyboardMarkup{inline_keyboard: inline_keyboard}
  end
end
