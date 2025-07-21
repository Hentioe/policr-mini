defmodule PolicrMiniWeb.AdminV2.API.SchemeController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Chats.Scheme
  alias PolicrMini.DefaultsServer

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  def update_default(conn, params) do
    # 接收新版本参数并转换到旧版本
    params = Scheme.cast_from_new_params(params)

    with {:ok, scheme} <- DefaultsServer.update_scheme_sync(params) do
      render(conn, "show.json", %{scheme: scheme})
    end
  end
end
