defmodule PolicrMiniBot.GridCAPTCHATest do
  use ExUnit.Case

  import PolicrMiniBot.GridCAPTCHA

  test "make!/2" do
    {:ok, _} = PolicrMiniBot.ImageProvider.start_link([])

    data = make!(-1, %{})

    assert length(data.candidates) == 3
    assert length(List.flatten(data.candidates)) == 9
    assert length(data.correct_indices) == 1
  end
end
