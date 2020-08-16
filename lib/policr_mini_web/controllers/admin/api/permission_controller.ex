defmodule PolicrMiniWeb.Admin.API.PermissionController do
  @moduledoc """
  和权限相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  # alias PolicrMini.{PermissionBusiness}

  action_fallback PolicrMiniWeb.API.FallbackController
end
