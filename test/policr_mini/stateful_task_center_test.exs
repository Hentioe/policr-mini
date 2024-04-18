defmodule PolicrMini.StatefulTaskCenterTest do
  use ExUnit.Case, async: false

  import PolicrMini.StatefulTaskCenter

  test "schedule/2" do
    schedule("hello", fn -> :hello end)

    :timer.sleep(10)

    job = Map.get(state(), "hello")
    assert match?(%{name: "hello", ok: true, result: :hello}, job)
  end

  test "schedule/2 with runtime error" do
    schedule("hello", fn -> raise "this is a runtime error" end)

    :timer.sleep(10)

    job = Map.get(state(), "hello")
    assert match?(%{name: "hello", ok: false, result: "this is a runtime error"}, job)
  end
end
