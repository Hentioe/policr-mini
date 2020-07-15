defmodule PolicrMiniWeb.PageControllerTest do
  use PolicrMiniWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "载入中 - PolicrMini"
  end
end
