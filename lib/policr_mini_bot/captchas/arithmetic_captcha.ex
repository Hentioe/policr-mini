defmodule PolicrMiniBot.ArithmeticCaptcha do
  @moduledoc """
  提供算术验证服务的模块。
  """

  use PolicrMiniBot.Captcha

  @number_range 1..50

  @doc """
  生成算术验证数据。
  """
  @impl true
  def make! do
    # 生成左数
    ln = @number_range |> Enum.random()
    # 生成右数
    rn = @number_range |> Enum.random()
    # 计算正确答案
    correct_answer = ln + rn
    # 生成错误答案列表
    wrong_answers =
      @number_range
      |> Enum.filter(fn n -> n != correct_answer end)
      |> Enum.map(fn n -> n end)
      |> Enum.take_random(4)

    candidates =
      ([correct_answer] ++ wrong_answers)
      |> Enum.shuffle()

    # 查找正确答案的索引
    correct_index = (candidates |> Enum.find_index(fn answer -> answer == correct_answer end)) + 1

    %Captcha.Data{
      question: "#{ln} + #{rn} = ?",
      candidates: [candidates],
      correct_indices: [correct_index]
    }
  end
end
