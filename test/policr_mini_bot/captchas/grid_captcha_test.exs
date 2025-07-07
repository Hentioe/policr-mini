defmodule PolicrMiniBot.GridCAPTCHATest do
  use ExUnit.Case

  import PolicrMiniBot.GridCAPTCHA

  test "make!/2" do
    data = make!(nil, %{})

    assert length(data.candidates) == 3
    assert length(List.flatten(data.candidates)) == 9
    assert length(data.correct_indices) == 1
  end
end
