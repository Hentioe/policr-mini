defmodule PolicrMiniWeb.ConsoleV2.TMAAuth do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn
  import PolicrMiniWeb.ConsoleV2.ViewHelper, only: [failure: 1]

  alias PolicrMini.Accounts

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case parse_tma(get_req_header(conn, "authorization")) do
      {:ok, user_info, raw} ->
        check_tma(conn, user_info, raw)

      {:error, :missing} ->
        fallback_tma_user_id =
          Application.get_env(:policr_mini, __MODULE__)[:fallback_tma_user_id]

        if fallback_tma_user_id do
          assign(conn, :user, Accounts.get_user(fallback_tma_user_id))
        else
          resp_unauthorized(conn)
        end

      {:error, _} ->
        resp_unauthorized(conn)
    end
  end

  defp parse_tma([<<"tma " <> rest>>]) do
    user_json = rest |> URI.decode_www_form() |> URI.decode_query() |> Map.get("user")

    {:ok, JSON.decode!(user_json), rest}
  end

  defp parse_tma([]), do: {:error, :missing}
  defp parse_tma(_), do: {:error, :invalid}

  defp check_tma(conn, user_info, raw) when is_map(user_info) do
    case TelegramMiniappValidation.validate(raw, Telegex.Instance.token(), 3600) do
      {:ok, _} -> load_user(conn, user_info)
      {:error, _} -> resp_unauthorized(conn)
    end
  end

  defp load_user(conn, user_info) do
    id = user_info["id"]

    user =
      if user = Accounts.get_user(id) do
        user
      else
        params = %{
          username: user_info["username"],
          first_name: user_info["first_name"],
          last_name: user_info["last_name"],
          # todo: 添加 language_code 字段
          # language_code: user_info["language_code"],
          photo: user_info["photo_url"],
          token_ver: 0
        }

        # todo: 处理 AMA 认证中的用户插入错误
        {:ok, user} = Accounts.upsert_user(id, params)

        user
      end

    assign(conn, :user, user)
  end

  defp resp_unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(JSON.encode!(failure("Unauthorized")))
    |> halt()
  end
end
