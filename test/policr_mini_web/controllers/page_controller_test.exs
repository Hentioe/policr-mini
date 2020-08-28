defmodule PolicrMiniWeb.PageControllerTest do
  use PolicrMiniWeb.ConnCase

  # TODO：此处初始化  :ets 中的 :bot_info 表的模拟数据。
  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "载入中 - "
  end
end
