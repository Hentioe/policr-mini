defmodule PolicrMini.Instance do
  @moduledoc """
  实例上下文。
  """

  use PolicrMini.Context

  import Ecto.Query, warn: false

  alias PolicrMini.Repo
  alias PolicrMini.Instance.Term

  @type term_written_returns :: {:ok, Term.t()} | {:error, Ecto.Changeset.t()}

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
end
