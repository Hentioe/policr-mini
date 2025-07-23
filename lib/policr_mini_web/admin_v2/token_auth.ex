defmodule PolicrMiniWeb.AdminV2.TokenAuth do
  @moduledoc false

  # todo: 根据 from 的值，重定向到页面或响应 JSON 错误

  alias PolicrMini.Schema.User
  alias PolicrMini.Accounts

  import Plug.Conn
  import PolicrMiniWeb.AdminV2.ViewHelper, only: [failure: 1]

  @type payload :: %{user_id: integer(), token_ver: integer()}

  @namespace "admin auth"
  # 24 hours
  @max_age 60 * 60 * 24

  def namespace, do: @namespace
  def max_age, do: @max_age

  def init(_opts) do
    %{
      root_path: "/admin/v2",
      cookie_name: "auth"
    }
  end

  def call(conn, %{root_path: root_path, cookie_name: cookie_name} = _opts) do
    {from, token} = load_token(conn, cookie_name)

    case verify(token) do
      {:ok, user} ->
        case from do
          :query ->
            # todo: 重定向到当前页面，而不是后台首页
            conn
            |> put_resp_cookie(cookie_name, token, max_age: @max_age, path: root_path)
            |> redirect_to(root_path)

          :cookie ->
            assign(conn, :user, user)
        end

      {:error, _reason} ->
        resp_unauthorized(conn)
    end
  end

  @spec load_token(Plug.Conn.t(), String.t()) :: {:query | :cookie, String.t()} | nil
  defp load_token(%Plug.Conn{} = conn, name) do
    cond do
      token = get_query(conn, name) ->
        {:query, token}

      token = get_cookie(conn, name) ->
        {:cookie, token}

      true ->
        nil
    end
  end

  @spec get_query(Plug.Conn.t(), String.t()) :: String.t() | nil
  defp get_query(conn, name) do
    conn
    |> fetch_query_params()
    |> Map.get(:query_params)
    |> Map.get(name)
  end

  @spec get_cookie(Plug.Conn.t(), String.t()) :: String.t() | nil
  defp get_cookie(conn, name) do
    conn
    |> fetch_cookies()
    |> Map.get(:req_cookies)
    |> Map.get(name)
  end

  @spec verify(String.t()) :: {:ok, User.t()} | {:error, atom()}
  defp verify(token) do
    case Phoenix.Token.verify(PolicrMiniWeb.Endpoint, @namespace, token, max_age: @max_age) do
      {:ok, auth} ->
        check_auth(auth)

      err ->
        err
    end
  end

  @spec check_auth(payload()) :: {:ok, User.t()} | {:error, :not_found | :revoked}
  defp check_auth(%{user_id: user_id, token_ver: token_ver}) do
    case Accounts.get_user(user_id) do
      nil ->
        {:error, :not_found}

      user when is_struct(user, User) ->
        if user.token_ver == token_ver do
          {:ok, user}
        else
          # 被吊销
          {:error, :revoked}
        end
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
    |> Phoenix.Controller.json(failure("Unauthorized"))
    |> halt()
  end
end
