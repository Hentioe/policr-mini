defmodule PolicrMiniWeb.TokenAuthentication do
  @moduledoc """
  验证 Token 的有效性的 plug。

  默认情况下此插件适配页面访问，授权不通过将重定向到登录链接。给 `opts` 关键字添加 `:from` 配置可修改适配目标。
  支持两种 `:from` 值，分别是 `:page`（默认）和 `:api`。适配 API 将响应 JSON 文本和 `401` 状态码。
  """

  @expired_sec 60 * 60 * 24

  @type auth_info :: %{user_id: integer(), token_ver: integer()}

  import Plug.Conn

  alias PolicrMini.Schema.User
  alias PolicrMini.UserBusiness

  def init(opts) do
    opts
    |> Keyword.put_new(:from, :admin)
    |> Enum.into(%{})
  end

  def call(conn, %{from: :admin}) do
    {token_from, token} = find_token(conn)

    if user = verify(token) do
      case token_from do
        :query ->
          # 将 token 写入 cookie 并重定向到不带参数的 admin 页面
          # TODO: 此处不应该直接重定向到后台首页，而是当前页面
          conn
          |> put_resp_cookie("token", token, max_age: @expired_sec, path: "/admin")
          |> redirect_to("/admin")

        :cookie ->
          assign(conn, :user, user)
      end
    else
      redirect_to(conn, "/login")
    end
  end

  def call(conn, %{from: :console}) do
    {token_from, token} = find_token(conn, "id_token")

    if user = verify(token) do
      case token_from do
        :query ->
          # 将 token 写入 cookie 并重定向到不带参数的 console 页面
          # TODO: 此处不应该直接重定向到后台首页，而是当前页面
          conn
          # 由于控制台依赖 admin API，所以需要在 admin 路径下设置 token
          |> put_resp_cookie("token", token, max_age: @expired_sec, path: "/admin")
          |> put_resp_cookie("id_token", token, max_age: @expired_sec, path: "/console")
          |> redirect_to("/console")

        :cookie ->
          assign(conn, :user, user)
      end
    else
      # TODO: 重定向到进入控制台的说明页面
      resp_unauthorized(conn)
    end
  end

  def call(conn, %{from: :admin_api}) do
    {_, token} = find_token(conn)

    if user = verify(token) do
      assign(conn, :user, user)
    else
      resp_unauthorized(conn)
    end
  end

  def call(conn, %{from: :console_api}) do
    {_, token} = find_token(conn, "id_token")

    if user = verify(token) do
      assign(conn, :user, user)
    else
      resp_unauthorized(conn)
    end
  end

  @spec find_token(Plug.Conn.t(), String.t()) :: {:query | :cookie, String.t()} | nil
  defp find_token(%Plug.Conn{} = conn, name \\ "token") do
    token =
      conn
      |> fetch_query_params()
      |> Map.get(:query_params)
      |> Map.get(name)

    token = token && String.trim(token)

    if token do
      {:query, token}
    else
      token =
        conn
        |> fetch_cookies()
        |> Map.get(:req_cookies)
        |> Map.get(name)

      token = token && String.trim(token)

      {:cookie, token}
    end
  end

  @spec verify(String.t()) :: User.t() | nil
  defp verify(token) do
    case Phoenix.Token.verify(PolicrMiniWeb.Endpoint, "user auth", token, max_age: @expired_sec) do
      {:ok, auth} ->
        check_auth_info(auth)

      _ ->
        nil
    end
  end

  @spec check_auth_info(auth_info) :: User.t() | nil
  defp check_auth_info(%{user_id: user_id, token_ver: token_ver}) do
    case UserBusiness.get(user_id) do
      {:ok, user} ->
        if user.token_ver == token_ver, do: user, else: nil

      {:error, :not_found, _} ->
        nil
    end
  end

  @spec redirect_to(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp redirect_to(%Plug.Conn{} = conn, path) do
    conn
    |> Phoenix.Controller.redirect(to: path)
    |> halt()
  end

  @spec resp_unauthorized(Plug.Conn.t()) :: Plug.Conn.t()
  defp resp_unauthorized(%Plug.Conn{} = conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{errors: %{description: "Unauthorized"}})
    |> halt()
  end
end
