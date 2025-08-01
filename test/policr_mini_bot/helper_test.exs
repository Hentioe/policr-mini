defmodule PolicrMiniBot.HelperTest do
  use ExUnit.Case
  doctest PolicrMiniBot.Helper

  import PolicrMiniBot.Helper

  alias PolicrMiniBot.Exceptions.InvalidDefaultKey

  test "default!/1" do
    # 测试是否产生 InvalidDefaultKey 异常
    assert_raise InvalidDefaultKey, fn ->
      default!(:invalid_key)
    end
  end
end
