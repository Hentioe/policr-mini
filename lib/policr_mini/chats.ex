defmodule PolicrMini.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, only: [from: 2, dynamic: 2]

  alias PolicrMini.Repo
  alias PolicrMini.Chats.Scheme

  @type scheme_written_returns :: {:ok, Scheme.t()} | {:error, Ecto.Changeset.t()}

  def create_scheme(params) do
    %Scheme{} |> Scheme.changeset(params) |> Repo.insert()
  end

  @default_id 0
  def create_default_scheme(params) do
    %Scheme{chat_id: @default_id} |> Scheme.changeset(params) |> Repo.insert()
  end

  def delete_scheme(scheme) when is_struct(scheme, Scheme) do
    Repo.delete(scheme)
  end

  def update_scheme(%Scheme{} = scheme, params) do
    scheme |> Scheme.changeset(params) |> Repo.update()
  end

  @spec find_scheme(integer | binary) :: Scheme.t() | nil
  def find_scheme(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    from(s in Scheme, where: s.chat_id == ^chat_id, limit: 1) |> Repo.one()
  end

  @type find_scheme_opts :: [{:chat_id, integer()}]

  # TODO: 添加测试。
  @spec find_scheme(find_scheme_opts) :: Scheme.t() | nil
  def find_scheme(options) when is_list(options) do
    filter_chat_id =
      if chat_id = options[:chat_id], do: dynamic([s], s.chat_id == ^chat_id), else: true

    from(s in Scheme, where: ^filter_chat_id) |> Repo.one()
  end

  @spec fetch_scheme(integer | binary) :: scheme_written_returns
  def fetch_scheme(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    case find_scheme(chat_id) do
      nil ->
        create_scheme(%{
          chat_id: chat_id
        })

      scheme ->
        {:ok, scheme}
    end
  end

  @default_scheme %{
    verification_mode: :image,
    verification_entrance: :unity,
    verification_occasion: :private,
    seconds: 300,
    timeout_killing_method: :kick,
    wrong_killing_method: :kick,
    is_highlighted: true,
    mention_text: :mosaic_full_name,
    image_answers_count: 4,
    service_message_cleanup: [:joined]
  }

  @doc """
  获取默认方案，如果不存在将自动创建。
  """
  @spec fetch_default_scheme :: scheme_written_returns
  def fetch_default_scheme do
    Repo.transaction(fn ->
      case find_scheme(@default_id) || create_default_scheme(@default_scheme) do
        {:ok, scheme} ->
          # 创建了一个新的方案。
          scheme

        {:error, e} ->
          # 创建方案发生错误。
          Repo.rollback(e)

        scheme ->
          # 方案已存在。
          migrate_default_in_trans(scheme)
      end
    end)
  end

  @spec migrate_default_in_trans(Scheme.t()) :: Scheme.t() | no_return
  defp migrate_default_in_trans(scheme) do
    attrs = %{}

    # 此处填充后续在方案中添加的新字段，避免方案已存在时这些字段出现 `nil` 值。
    attrs = if scheme.mention_text, do: attrs, else: %{mention_text: @default_scheme.mention_text}

    attrs =
      if scheme.image_answers_count,
        do: attrs,
        else: Map.put(attrs, :image_answers_count, @default_scheme.image_answers_count)

    attrs =
      if scheme.service_message_cleanup,
        do: attrs,
        else: Map.put(attrs, :service_message_cleanup, @default_scheme.service_message_cleanup)

    case update_scheme(scheme, attrs) do
      {:ok, scheme} -> scheme
      {:error, e} -> Repo.rollback(e)
    end
  end
end
