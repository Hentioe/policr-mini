defmodule PolicrMiniBot.Helper.Syncing do
  @moduledoc """
  提供同步相关的函数。
  """

  alias PolicrMini.Instances
  alias PolicrMini.Instances.Chat
  alias PolicrMini.Schema.{User, Permission}
  alias PolicrMini.UserBusiness
  alias Telegex.Type.{ChatMember, ChatMemberAdministrator, ChatMemberOwner}

  import PolicrMiniBot.Helper

  require Logger

  @doc """
  同步 chat 的权限列表。

  同步过后，将重新预加载权限列表，并返回新的 chat。
  """
  @spec sync_for_chat_permissions(Chat.t()) :: {:ok, Chat.t()} | {:error, any}
  def sync_for_chat_permissions(chat) do
    case Telegex.get_chat_administrators(chat.id) do
      {:ok, administrators} ->
        # 过滤管理员中的机器人
        administrators = Enum.reject(administrators, fn member -> member.user.is_bot end)

        # 更新用户列表。
        # TODO：处理可能发生的用户同步错误。
        Enum.each(administrators, &sync_for_user/1)

        # 更新管理员列表。
        # 默认具有可读权限，可写权限由 `can_restrict_members` 决定。

        memeber_permission_mapping = fn member ->
          is_owner = member.status == "creator"
          can_restrict_members? = can_restrict_members?(member)

          %Permission{
            user_id: member.user.id,
            tg_is_owner: is_owner,
            tg_can_restrict_members: can_restrict_members?,
            tg_can_promote_members: can_promote_members?(member),
            readable: true,
            writable: can_restrict_members?
          }
        end

        permissions = Enum.map(administrators, memeber_permission_mapping)

        try do
          Instances.reset_chat_permissions!(chat, permissions)
          # 重新载入此 chat 的权限列表。
          chat = PolicrMini.Repo.preload(chat, [:permissions])

          {:ok, chat}
        rescue
          e ->
            Logger.error("Sync permissions failed: #{inspect(error: e, chat_id: chat.id)}")

            {:error, e}
        end

      e ->
        e
    end
  end

  @spec sync_for_user(ChatMember.t()) :: {:ok, User.t()} | {:error, any}

  def sync_for_user(chat_member)
      when is_struct(chat_member, ChatMemberAdministrator) or
             is_struct(chat_member, ChatMemberOwner) do
    user = chat_member.user

    user_params = %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      username: user.username
    }

    case UserBusiness.fetch(user.id, user_params) do
      {:ok, _user} = ok_user ->
        ok_user

      {:error, _e} = err ->
        err
    end
  end
end
