defmodule PolicrMini.SchemeBusiness do
  @moduledoc """
  方案的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.Scheme

  import Ecto.Query, only: [from: 2, dynamic: 2]

  def create(params) do
    %Scheme{} |> Scheme.changeset(params) |> Repo.insert()
  end

  @default_id 0
  def create_default(params) do
    %Scheme{chat_id: @default_id} |> Scheme.changeset(params) |> Repo.insert()
  end

  def delete(scheme) when is_struct(scheme, Scheme) do
    Repo.delete(scheme)
  end

  def update(%Scheme{} = scheme, params) do
    scheme |> Scheme.changeset(params) |> Repo.update()
  end

  @spec find(integer | binary) :: Scheme.t() | nil
  def find(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    from(s in Scheme, where: s.chat_id == ^chat_id, limit: 1) |> Repo.one()
  end

  @type find_opts :: [{:chat_id, integer()}]

  # TODO: 添加测试
  @spec find(find_opts) :: Scheme.t() | nil
  def find(options) when is_list(options) do
    filter_chat_id =
      if chat_id = options[:chat_id], do: dynamic([s], s.chat_id == ^chat_id), else: true

    from(s in Scheme, where: ^filter_chat_id) |> Repo.one()
  end

  @spec fetch(integer | binary) :: written_returns
  def fetch(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    case find(chat_id) do
      nil ->
        create(%{
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
    is_highlighted: true
  }

  @doc """
  获取默认方案，如果不存在将自动创建。
  """
  @spec fetch_default :: {:ok, Scheme.t()} | {:error, any}
  def fetch_default do
    Repo.transaction(fn ->
      case find(@default_id) || create_default(@default_scheme) do
        {:ok, scheme} ->
          scheme

        {:error, e} ->
          Repo.rollback(e)

        scheme ->
          scheme
      end
    end)
  end
end
