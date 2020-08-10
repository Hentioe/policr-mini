defmodule PolicrMini.ChatBusiness do
  @moduledoc """
  群组的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schemas.Chat

  import Ecto.Query, only: [from: 2]

  alias PolicrMini.Schemas.Permission
  alias PolicrMini.PermissionBusiness

  @typep written_returns :: {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map()) :: written_returns()
  def create(params) do
    %Chat{} |> Chat.changeset(params) |> Repo.insert()
  end

  @spec update(Chat.t(), map()) :: written_returns()
  def update(%Chat{} = chat, attrs) do
    chat |> Chat.changeset(attrs) |> Repo.update()
  end

  @spec fetch(integer(), map()) :: written_returns()
  def fetch(id, params) when is_integer(id) do
    case id |> get() do
      {:error, :not_found, _} -> create(params |> Map.put(:id, id))
      {:ok, chat} -> chat |> update(params)
    end
  end

  @spec takeover_cancelled(Chat.t()) :: written_returns()
  def takeover_cancelled(%Chat{} = chat) do
    chat |> update(%{is_take_over: false})
  end

  @spec reset_administrators!(Chat.t(), [Permission.t()]) :: :ok
  def reset_administrators!(%Chat{} = chat, permissions) when is_list(permissions) do
    permission_params_list =
      permissions |> Enum.map(fn p -> p |> struct(chat_id: chat.id) |> Map.from_struct() end)

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
        {:ok, _} = PermissionBusiness.fetch(chat.id, params.user_id, params)
      end)

      :ok
    end)
  end

  @spec find_list(integer()) :: [Chat.t()]
  def find_list(user_id) when is_integer(user_id) do
    from(p in Permission, where: p.user_id == ^user_id)
    |> Repo.all()
    |> Repo.preload([:chat])
    |> Enum.map(fn p -> p.chat end)
  end

  @spec find_administrators(integer()) :: [Chat.t()]
  def find_administrators(chat_id) do
    from(p in Permission, where: p.chat_id == ^chat_id)
    |> Repo.all()
    |> Repo.preload([:user])
    |> Enum.map(fn p -> p.user end)
  end

  @spec find_takeovered :: [Chat.t()]
  def find_takeovered do
    from(c in Chat, where: c.is_take_over == true) |> Repo.all()
  end

  @keywords_separator_re ~r/ +/

  # TODO: 缺乏测试。
  @doc """
  搜索群组列表。

  参数 `keywords` 会参与 `title` 和 `description` 两个字段的模糊查询，以空格分隔的多个关键字可以满足关键字之间的 `and` 关系。

  注意：当前使用空格分隔的关键字仍然具备从左至右的关系，以后可能会顺序无关。
  """
  @spec search(String.t()) :: [Chat.t()]
  def search(keywords) do
    searching_str = "%" <> (keywords |> String.replace(@keywords_separator_re, "%")) <> "%"

    from(c in Chat, where: ilike(c.title, ^searching_str) or ilike(c.description, ^searching_str))
    |> Repo.all()
  end
end
