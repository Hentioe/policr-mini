defmodule PolicrMini.Bot.ArithmeticCaptcha do
  @moduledoc """
  提供算术验证服务的模块。
  """

  use PolicrMini.Bot.Captcha

  @number_range 1..50

  @doc """
  制作算术验证数据。
  """
  @impl true
  def make do
    # 生成左数
    ln = @number_range |> Enum.random()
    # 生成右数
    rn = @number_range |> Enum.random()
    # 计算正确答案
    correct_answer = ln + rn
    # 生成错误答案候选列表
    wrong_candidates =
      @number_range
      |> Enum.filter(fn n -> n != correct_answer end)
      |> Enum.map(fn n -> n end)
      |> Enum.shuffle()

    # 生成错误答案列表
    {_, wrong_answers} =
      1..4
      |> Enum.reduce({wrong_candidates, []}, fn _, {candidates, answers} ->
        {answer, candidates} = candidates |> List.pop_at(0)

        {candidates, answers ++ [answer]}
      end)

    candidates =
      ([correct_answer] ++ wrong_answers)
      |> Enum.shuffle()

    correct_index =
      candidates
      |> Enum.with_index(1)
      |> Enum.reduce(0, fn {answer, index}, correct_index ->
        correct_index =
          if correct_index > 0,
            do: correct_index,
            else: if(answer == correct_answer, do: index, else: 0)

        correct_index
      end)

    %Captcha.Data{
      question: "#{ln} + #{rn} = ?",
      candidates: [candidates],
      correct_indices: [correct_index]
    }
  end
end
