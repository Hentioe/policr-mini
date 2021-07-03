defmodule PolicrMini.Instances do
  @moduledoc """
  实例上下文。
  """

  use PolicrMini.Context

  import Ecto.Query, warn: false

  alias PolicrMini.{Repo, PermissionBusiness}
  alias PolicrMini.Schema.Permission
  alias __MODULE__.{Term, Chat}

  @type term_written_returns :: {:ok, Term.t()} | {:error, Ecto.Changeset.t()}
  @type chat_written_returns :: {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}

  @term_id 1

  @doc """
  提取服务条款。

  如果不存在将自动创建。
  """

  @spec fetch_term() :: term_written_returns
  def fetch_term do
    Repo.transaction(fn ->
      case Repo.get(Term, @term_id) || create_term(%{id: @term_id}) do
        {:ok, term} ->
          term

        {:error, e} ->
          Repo.rollback(e)

        term ->
          term
      end
    end)
  end

  @doc """
  创建服务条款。
  """
  @spec create_term(params) :: term_written_returns
  def create_term(params) do
    %Term{} |> Term.changeset(params) |> Repo.insert()
  end

  @doc """
  更新服务条款。
  """
  @spec update_term(Term.t(), map) :: term_written_returns
  def update_term(term, params) do
    term |> Term.changeset(params) |> Repo.update()
  end

  @doc """
  删除服务条款。
  """
  def delete_term(term) when is_struct(term, Term) do
    Repo.delete(term)
  end

  @doc """
  创建群组。
  """
  @spec create_chat(params) :: chat_written_returns
  def create_chat(params) do
    %Chat{} |> Chat.changeset(params) |> Repo.insert()
  end

  @doc """
  更新群组。
  """
  @spec update_chat(Chat.t(), params) :: chat_written_returns
  def update_chat(chat, params) when is_struct(chat, Chat) do
    chat |> Chat.changeset(params) |> Repo.update()
  end

  @doc """
  提取并更新群组，不存在则根据 ID 创建。
  """
  @spec fetch_and_update_chat(integer, params) :: chat_written_returns
  def fetch_and_update_chat(id, params) do
    Repo.transaction(fn ->
      case Repo.get(Chat, id) || create_chat(Map.put(params, :id, id)) do
        {:ok, chat} ->
          # 创建成功，直接返回。
          chat

        {:error, e} ->
          Repo.rollback(e)

        # 已存在，更新并返回。
        chat ->
          update_chat_in_transaction(chat, params)
      end
    end)
  end

  @spec update_chat_in_transaction(Chat.t(), params) :: Chat.t() | no_return
  defp update_chat_in_transaction(chat, params) do
    case update_chat(chat, params) do
      {:ok, chat} -> chat
      {:error, e} -> Repo.rollback(e)
    end
  end

  @doc """
  取消指定群组的接管。
  """
  @spec cancel_chat_takeover(Chat.t()) :: chat_written_returns
  def cancel_chat_takeover(chat) when is_struct(chat, Chat) do
    update_chat(chat, %{is_take_over: false})
  end

  @doc """
  重置指定群组的权限列表。
  """
  @spec reset_chat_permissions!(Chat.t(), [Permission.t()]) :: :ok
  def reset_chat_permissions!(chat, permissions)
      when is_struct(chat, Chat) and is_list(permissions) do
    permission_params_list =
      permissions |> Enum.map(fn p -> p |> struct(chat_id: chat.id) |> Map.from_struct() end)

    # TODO: 此处的事务需保证具有回滚的能力并能够返回错误结果。
    Repo.transaction(fn ->
      # 获取原始用户列表和当前用户列表
      original_user_id_list =
        PermissionBusiness.find_list(chat_id: chat.id) |> Enum.map(fn p -> p.user_id end)

      current_user_id_list = permission_params_list |> Enum.map(fn p -> p.user_id end)

      # 求出当前用户列表中已不包含的原始用户，删除之
      # TODO: 待优化方案：一条语句删除
      original_user_id_list
      |> Enum.filter(fn id -> !(current_user_id_list |> Enum.member?(id)) end)
      |> Enum.each(fn user_id -> PermissionBusiness.delete(chat.id, user_id) end)

      # 将所有管理员权限信息写入（添加或更新）
      permission_params_list
      |> Enum.each(fn params ->
        {:ok, _} = PermissionBusiness.sync(chat.id, params.user_id, params)
      end)

      :ok
    end)
  end
end
