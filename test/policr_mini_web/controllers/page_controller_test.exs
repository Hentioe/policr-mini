defmodule PolicrMiniWeb.PageControllerTest do
  use PolicrMiniWeb.ConnCase

  alias PolicrMiniBot.Info

  # TODO：此处初始化 :ets 中的 `PolicrMiniBot.Info` 表的模拟数据。
  test "GET /", %{conn: conn} do
    :ets.new(Info, [:set, :named_table])

    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "载入中 - "
  end
end
