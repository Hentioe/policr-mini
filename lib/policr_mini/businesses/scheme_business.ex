defmodule PolicrMini.SchemeBusiness do
  @moduledoc """
  方案的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schemas.Scheme

  import Ecto.Query, only: [from: 2, dynamic: 2]

  def create(params) do
    %Scheme{} |> Scheme.changeset(params) |> Repo.insert()
  end

  def update(%Scheme{} = scheme, params) do
    scheme |> Scheme.changeset(params) |> Repo.update()
  end

  @spec find(integer()) :: Scheme.t() | nil
  def find(chat_id) when is_integer(chat_id) do
    from(s in Scheme, where: s.chat_id == ^chat_id, limit: 1) |> Repo.one()
  end

  @type find_opts :: [{:chat_id, integer()}]

  # TODO: 添加测试
  @spec find(find_opts) :: Scheme.t() | nil
  def find(options) do
    filter_chat_id =
      if chat_id = options[:chat_id], do: dynamic([s], s.chat_id == ^chat_id), else: true

    from(s in Scheme, where: ^filter_chat_id) |> Repo.one()
  end

  @spec fetch(integer) :: {:ok, Scheme.t()} | {:error, Ecto.Changeset.t()}
  def fetch(chat_id) when is_integer(chat_id) do
    case find(chat_id) do
      nil ->
        create(%{
          chat_id: chat_id
        })

      scheme ->
        {:ok, scheme}
    end
  end
end
