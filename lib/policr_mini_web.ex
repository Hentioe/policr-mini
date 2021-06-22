defmodule PolicrMiniWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PolicrMiniWeb, :controller
      use PolicrMiniWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: PolicrMiniWeb

      import Plug.Conn
      import PolicrMiniWeb.Gettext
      alias PolicrMiniWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/policr_mini_web/templates",
        namespace: PolicrMiniWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import PolicrMiniWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import PolicrMiniWeb.ErrorHelpers
      import PolicrMiniWeb.Gettext
      alias PolicrMiniWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  @doc """
  创建一个用户 Token。

  目前唯一可能返回错误的情况是用户不存在，即 `{:error, :notfound}`。
  """
  @spec create_token(integer()) :: {:ok, String.t()} | {:error, :notfound}
  def create_token(user_id) do
    case PolicrMini.UserBusiness.get(user_id) do
      {:ok, user} ->
        token =
          Phoenix.Token.sign(PolicrMiniWeb.Endpoint, "user auth", %{
            user_id: user_id,
            token_ver: user.token_ver
          })

        {:ok, token}

      {:error, :not_found, _} ->
        {:error, :notfound}
    end
  end

  @type root_url_opts :: [{:has_end_slash, boolean}]

  @doc """
  获取根链接。

  ## 可选参数
  - `has_end_slash`: 链接结尾处是否包含斜杠。默认为 `true`。
  """
  @spec root_url(root_url_opts) :: String.t() | nil
  def root_url(opts \\ []) do
    root_url = Application.get_env(:policr_mini, PolicrMiniWeb)[:root_url]

    if root_url do
      has_end_slash = Keyword.get(opts, :has_end_slash, true)

      if has_end_slash do
        (String.ends_with?(root_url, "/") && root_url) || root_url <> "/"
      else
        (String.ends_with?(root_url, "/") && String.slice(root_url, 0..-2)) || root_url
      end
    end
  end
end
