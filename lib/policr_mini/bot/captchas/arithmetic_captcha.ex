defmodule PolicrMini.Bot.ArithmeticCaptcha do
  @moduledoc """
  提供算术验证服务的模块。
  """

  use PolicrMini.Bot.Captcha

  @doc """
  制作算术验证数据。
  TODO: 当前是静态测试数据，需要改为动态实现。
  """
  @impl true
  def made do
    {
      "1 + 1 = ?",
      [[1, 2, 3, 4, 5]],
      [2]
    }
  end
end
