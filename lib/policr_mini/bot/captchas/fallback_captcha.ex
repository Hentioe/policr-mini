defmodule PolicrMini.Bot.FallbackCaptcha do
  @moduledoc """
  提供备用验证服务的模块。
  当前此模块实现为「主动验证」，有且只有一个为正确的答案。
  能主动交互的用户即可通过的验证就是所谓的「主动验证」。它的表现为提供一个按钮并提示点击，此验证没有正确/错误之分。
  """

  use PolicrMini.Bot.Captcha

  @doc """
  生成主动验证数据。
  """
  @impl true
  def make! do
    %Captcha.Data{
      question: "点击「通过验证」按钮",
      candidates: [["通过验证"]],
      correct_indices: [1]
    }
  end
end
