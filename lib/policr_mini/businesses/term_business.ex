defmodule PolicrMini.TermBusiness do
  @moduledoc """
  服务条款的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.Term

  @type written_returns :: {:ok, Term.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map) :: written_returns
  def create(params) do
    %Term{} |> Term.changeset(params) |> Repo.insert()
  end

  @spec update(Term.t(), map) :: written_returns
  def update(term, params) do
    term |> Term.changeset(params) |> Repo.update()
  end

  # TODO: 缺乏测试。
  @spec fetch(integer) :: written_returns
  def fetch(id) do
    case get(id) do
      {:ok, term} -> {:ok, term}
      {:error, :not_found, _} -> create(%{id: id})
    end
  end

  def delete(term) when is_struct(term, Term) do
    Repo.delete(term)
  end
end
