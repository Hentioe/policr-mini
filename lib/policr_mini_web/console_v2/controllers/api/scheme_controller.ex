defmodule PolicrMiniWeb.ConsoleV2.API.SchemeController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Chats
  alias PolicrMini.Chats.Scheme

  import Canary.Plugs

  plug :authorize_resource, model: Scheme

  def update(conn, %{"id" => id} = params) do
    # 接收新版本参数并转换到旧版本
    params = Scheme.cast_from_new_params(params)

    with {:ok, scheme} <- Chats.load_scheme(id),
         {:ok, scheme} <- Chats.update_scheme(scheme, params) do
      render(conn, "show.json", scheme: scheme)
    end
  end
end
