defmodule PolicrMini.Settings do
  @moduledoc false

  use PolicrMini.Context

  alias PolicrMini.Repo
  alias PolicrMini.Instances.Term

  @term_id 1

  @spec get_term :: Term.t() | nil
  def get_term do
    Repo.get(Term, @term_id)
  end

  def upsert_term(content) when is_binary(content) do
    params = %{
      content: content
    }

    # 手动创建 updated_at 字段的值
    updated_at = DateTime.utc_now()

    %Term{id: @term_id}
    |> Term.changeset(params)
    |> PolicrMini.Repo.insert(
      on_conflict: [set: [content: content, updated_at: updated_at]],
      conflict_target: [:id]
    )
  end

  def create_term(params) do
    %Term{} |> Term.changeset(params) |> Repo.insert()
  end

  def update_term(term, params) do
    term |> Term.changeset(params) |> Repo.update()
  end

  def delete_term do
    case get_term() do
      nil ->
        {:ok, Term.default()}

      term when is_struct(term, Term) ->
        Repo.delete(term)
    end
  end
end
