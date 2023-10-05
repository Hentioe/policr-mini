defmodule PolicrMiniWeb.Helper do
  @moduledoc false

  alias PolicrMini.PermissionBusiness

  require Logger

  @type perm :: PermissionBusiness.permission()

  @doc """
  检查当前连接中的用户是否具备系统权限。

  如果用户是机器人的拥有者，将返回完整的权限列表（读/写）。
  """
  @spec check_sys_permissions(Plug.Conn.t(), [perm]) :: {:error, map} | {:ok, [perm]}
  def check_sys_permissions(%Plug.Conn{} = conn, requires \\ []) do
    %{assigns: %{user: %{id: user_id}}} = conn
    requires = if Enum.member?(requires, :readable), do: requires, else: [:readable] ++ requires

    # 如果当前用户是机器人拥有者，赋予 `:readable` 和 `:writable` 权限。
    perms =
      if user_id == owner_id() do
        [:readable, :writable]
      else
        []
      end

    match_permissions(perms, requires)
  end

  @doc """
  检查当前连接中的用户是否具备目标群组的权限。

  如果用户是机器人的拥有者，至少会存在一个 `:readable` 权限。
  """
  @spec check_permissions(Plug.Conn.t(), integer, [perm]) :: {:ok, [perm]} | {:error, map}
  def check_permissions(%Plug.Conn{} = conn, chat_id, requires \\ []) do
    %{assigns: %{user: %{id: user_id}}} = conn
    requires = if Enum.member?(requires, :readable), do: requires, else: [:readable] ++ requires

    perms = PermissionBusiness.has_permissions(chat_id, user_id)

    # 如果当前用户是机器人拥有者，赋予 `:readable` 权限。
    perms =
      if user_id == owner_id() && !Enum.member?(perms, :readable) do
        [:readable] ++ perms
      else
        perms
      end

    match_permissions(perms, requires)
  end

  @spec owner_id() :: integer
  defp owner_id, do: Application.get_env(:policr_mini, PolicrMiniBot)[:owner_id]

  @spec match_permissions([perm], [perm]) :: {:ok, [perm]} | {:error, map}
  defp match_permissions(perms, requires) do
    missing_perms = Enum.filter(requires, fn p -> !Enum.member?(perms, p) end)

    cond do
      Enum.empty?(perms) ->
        {:error, %{description: "does not have any permissions"}}

      !Enum.empty?(missing_perms) ->
        perms_str = combined_permissions(missing_perms)
        {:error, %{description: "missing #{perms_str} permissions"}}

      true ->
        {:ok, perms}
    end
  end

  @doc """
  组合权限列表为可读字符串消息的一部分。

  如果参数 `perms` 为空列表或 `nil` 将返回 `?` 字符串。这意味着传递了无效的参数，切记在调用前判断列表非空。

  ## 例子
      iex> PolicrMiniWeb.Helper.combined_permissions([:writable])
      "writable"
      iex> PolicrMiniWeb.Helper.combined_permissions([:readable, :writable])
      "readable and writable"
  """
  @spec combined_permissions([perm]) :: String.t()
  def combined_permissions([]), do: "?"
  def combined_permissions(nil), do: "?"

  def combined_permissions(perms) when is_list(perms) do
    last_index = length(perms) - 1

    perms
    |> Enum.with_index()
    |> Enum.reduce("", fn {perm, i}, acc ->
      acc = acc <> to_string(perm)
      acc = if i == last_index, do: acc, else: acc <> " and "

      acc
    end)
  end

  @doc """
  定义赞助的选项。

  此宏会生成 `@hints_map` 模块属性有用于查找，以及 `@hints_data` 模块属性用于序列化。
  """
  defmacro def_sp_opts(opts) do
    quote do
      @hints_map unquote(opts)
                 |> Enum.with_index()
                 |> Enum.into(%{}, fn {elem, index} -> {"@#{index}", elem} end)

      @hints_data Enum.map(@hints_map, fn {ref, {expected_to, amount}} ->
                    %{ref: ref, expected_to: expected_to, amount: amount}
                  end)
    end
  end
end
