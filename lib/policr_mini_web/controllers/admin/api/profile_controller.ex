defmodule PolicrMiniWeb.Admin.API.ProfileController do
  @moduledoc """
  全局属性的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.DefaultProvider

  require Logger

  action_fallback PolicrMiniWeb.API.FallbackController

  # 注意：此后台仍被旧用户后台「方案定制」页面使用，可检索代码 `/admin/api/profile` 判断是否移除。
  def index(conn, _params) do
    # 此 API 调用无需系统权限
    scheme = DefaultProvider.scheme()

    render(conn, "index.json", %{
      scheme: scheme
    })
  end
end
