defmodule PolicrMini.Instances do
  @moduledoc """
  实例上下文。
  """

  use PolicrMini.Context

  import Ecto.Query, warn: false

  alias PolicrMini.{Repo, PermissionBusiness}
  alias PolicrMini.Schema.Permission
  alias __MODULE__.{Term, Chat, Sponsor, SponsorshipHistory, SponsorshipAddress}

  @type term_written_returns ::
          {:ok, Term.t()} | {:error, Ecto.Changeset.t()}
  @type chat_written_returns ::
          {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}
  @type sponsor_written_returns ::
          {:ok, Sponsor.t()} | {:error, Ecto.Changeset.t()}
  @type sponsor_histories_written_returns ::
          {:ok, SponsorshipHistory.t()} | {:error, Ecto.Changeset.t()}
  @type sponsorship_addresses_written_returns ::
          {:ok, SponsorshipAddress.t()} | {:error, Ecto.Changeset.t()}

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

  @type find_chats_cont :: [taken_over: boolean, left_is_not: boolean]

  # TODO: 添加测试。
  @doc """
  查找群组列表。
  """
  @spec find_chats(find_chats_cont) :: [Chat.t()]
  def find_chats(cont \\ []) do
    taken_over = Keyword.get(cont, :taken_over)
    left_is_not = Keyword.get(cont, :left_is_not)

    filter_taken_over = (taken_over != nil && dynamic([c], c.is_take_over == ^taken_over)) || true

    filter_left_is_not =
      (left_is_not != nil && dynamic([c], is_nil(c.left) or c.left != ^left_is_not)) || true

    from(c in Chat,
      where: ^filter_taken_over,
      where: ^filter_left_is_not
    )
    |> Repo.all()
  end

  # TODO：添加测试。
  @doc """
  查询用户管理的群列表。

  将返回指定用户下具有可读权限的群组列表，并按照添加时间排序。
  **注意：函数不返回已离开的群组。**
  """
  @spec find_user_chats(integer) :: [Chat.t()]
  def find_user_chats(user_id) when is_integer(user_id) do
    from(p in Permission, where: p.user_id == ^user_id and p.readable == true)
    |> Repo.all()
    |> Repo.preload([:chat])
    |> Enum.map(fn p -> p.chat end)
    # TODO: 此处应基于 SQL 条件实现，而不是数据过滤
    |> Enum.filter(fn chat -> chat.left != true end)
  end

  @doc """
  已离开指定群组。
  """
  @spec chat_left(Chat.t()) :: chat_written_returns
  def chat_left(chat) do
    update_chat(chat, %{left: true})
  end

  @doc """
  取消指定群组的接管。
  """
  @spec cancel_chat_takeover(Chat.t()) :: chat_written_returns
  def cancel_chat_takeover(chat) when is_struct(chat, Chat) do
    update_chat(chat, %{is_take_over: false})
  end

  @doc """
  已离开群组且接管取消。
  """
  @spec chat_left_and_takeover_cancel(Chat.t()) :: chat_written_returns
  def chat_left_and_takeover_cancel(chat) do
    update_chat(chat, %{left: true, is_take_over: false})
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

  @spec create_sponsor(map) :: sponsor_written_returns
  def create_sponsor(params) do
    %Sponsor{uuid: UUID.uuid4()} |> Sponsor.changeset(params) |> Repo.insert()
  end

  @spec update_sponsor(Sponsor.t(), map) :: sponsor_written_returns
  def update_sponsor(sponsor, params) do
    sponsor |> Sponsor.changeset(params) |> Repo.update()
  end

  def delete_sponsor(sponsor) when is_struct(sponsor, Sponsor) do
    Repo.delete(sponsor)
  end

  @spec find_sponsors(keyword) :: [Sponsor.t()]
  def find_sponsors(_find_list_conts \\ []) do
    from(s in Sponsor, order_by: [desc: s.updated_at])
    |> Repo.all()
  end

  @type find_sponsor_conts :: [{:uuid, binary}]

  # TODO: 添加测试。
  @spec find_sponsor(find_sponsor_conts) :: Sponsor.t() | nil
  def find_sponsor(conts \\ []) do
    uuid = Keyword.get(conts, :uuid)

    filter_uuid = (uuid && dynamic([s], s.uuid == ^uuid)) || true

    from(s in Sponsor, where: ^filter_uuid) |> Repo.one()
  end

  defp fill_reached_at(params) do
    if params["has_reached"] do
      (params["reached_at"] in ["", nil] && Map.put(params, "reached_at", DateTime.utc_now())) ||
        params
    else
      params
    end
  end

  @spec create_sponsorship_histrory(map) :: sponsor_histories_written_returns
  def create_sponsorship_histrory(params) do
    params = fill_reached_at(params)

    %SponsorshipHistory{} |> SponsorshipHistory.changeset(params) |> Repo.insert()
  end

  # TODO: 添加测试。
  @spec create_sponsorship_histrory_with_sponsor(map) ::
          {:ok, SponsorshipHistory.t()} | {:error, any}
  def create_sponsorship_histrory_with_sponsor(params) do
    sponsor = params["sponsor"]

    # TODO: 此处的事务需保证具有回滚的能力并能够返回错误结果。
    Repo.transaction(fn ->
      with {:ok, sponsor} <- create_sponsor(sponsor),
           {:ok, sponsorship_history} <-
             create_sponsorship_histrory(Map.put(params, "sponsor_id", sponsor.id)) do
        Map.put(sponsorship_history, :sponsor, sponsor)
      else
        e -> e
      end
    end)
  end

  @spec update_sponsorship_histrory(SponsorshipHistory.t(), map) ::
          sponsor_histories_written_returns
  def update_sponsorship_histrory(sponsorship_history, params) do
    params = fill_reached_at(params)

    sponsorship_history |> SponsorshipHistory.changeset(params) |> Repo.update()
  end

  # TODO: 添加测试。
  @spec update_sponsorship_histrory_with_create_sponsor(SponsorshipHistory.t(), map) ::
          {:ok, SponsorshipHistory.t()} | {:error, any}
  def update_sponsorship_histrory_with_create_sponsor(sponsorship_history, params) do
    sponsor = params["sponsor"]

    # TODO: 此处的事务需保证具有回滚的能力并能够返回错误结果。
    Repo.transaction(fn ->
      with {:ok, sponsor} <- create_sponsor(sponsor),
           {:ok, sponsorship_history} <-
             update_sponsorship_histrory(
               sponsorship_history,
               Map.put(params, "sponsor_id", sponsor.id)
             ) do
        Map.put(sponsorship_history, :sponsor, sponsor)
      else
        e -> e
      end
    end)
  end

  def delete_sponsorship_histrory(sponsorship_history)
      when is_struct(sponsorship_history, SponsorshipHistory) do
    Repo.delete(sponsorship_history)
  end

  @spec reached_sponsorship_histrory(SponsorshipHistory.t()) :: sponsor_histories_written_returns
  def reached_sponsorship_histrory(sponsorship_history) do
    update_sponsorship_histrory(sponsorship_history, %{
      has_reached: true,
      reached_at: DateTime.utc_now()
    })
  end

  @type find_list_cont :: [
          {:has_reached, boolean},
          {:preload, [:sponsor]},
          {:order_by, [{:desc | :asc | :desc_nulls_first, atom}]},
          {:display, :not_hidden | :hidden}
        ]

  @spec find_sponsorship_histrories(find_list_cont) :: [SponsorshipHistory.t()]
  def find_sponsorship_histrories(find_list_cont \\ []) do
    has_reached = Keyword.get(find_list_cont, :has_reached)
    preload = Keyword.get(find_list_cont, :preload, [])
    order_by = Keyword.get(find_list_cont, :order_by, desc: :reached_at)
    display = Keyword.get(find_list_cont, :display)

    filter_has_reached =
      (has_reached != nil && dynamic([s], s.has_reached == ^has_reached)) || true

    filter_display =
      case display do
        :not_hidden -> dynamic([s], is_nil(s.hidden) or s.hidden == false)
        :hidden -> dynamic([s], s.hidden == true)
        _ -> true
      end

    from(s in SponsorshipHistory,
      where: ^filter_has_reached,
      where: ^filter_display,
      order_by: ^order_by,
      preload: ^preload
    )
    |> Repo.all()
  end

  @doc """
  创建一个赞助地址。
  """
  @spec create_sponsorship_address(map) :: sponsorship_addresses_written_returns
  def create_sponsorship_address(params) do
    %SponsorshipAddress{} |> SponsorshipAddress.changeset(params) |> Repo.insert()
  end

  @doc """
  删除一个赞助地址。
  """
  def delete_sponsorship_address(sponsorship_address)
      when is_struct(sponsorship_address, SponsorshipAddress) do
    Repo.delete(sponsorship_address)
  end

  @doc """
  更新一个赞助地址。
  """
  @spec update_sponsorship_address(SponsorshipAddress.t(), map) ::
          sponsorship_addresses_written_returns
  def update_sponsorship_address(sponsorship_address, params) do
    sponsorship_address |> SponsorshipAddress.changeset(params) |> Repo.update()
  end

  @type find_sponsorship_addresses_cont :: []

  @doc """
  查找赞助地址列表。
  """
  @spec find_sponsorship_addresses(find_sponsorship_addresses_cont) :: [SponsorshipAddress.t()]
  def find_sponsorship_addresses(_find_sponsorship_addresses_cont \\ []) do
    from(s in SponsorshipAddress) |> Repo.all()
  end
end
