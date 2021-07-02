defmodule PolicrMini.TermBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory

  import PolicrMini.Instance

  def build_term_params(attrs \\ []) do
    term = Factory.build(:term)

    term
    |> struct(attrs)
    |> Map.from_struct()
  end

  test "fetch_term/0" do
    {:ok, term} = fetch_term()

    assert term.id == 1
  end

  test "create_term/1" do
    params = build_term_params()
    {:ok, term} = create_term(params)

    assert term.id == params.id
    assert term.content == params.content
  end

  test "update_term/2" do
    params = build_term_params()
    {:ok, term1} = create_term(params)

    updated_content = "更新后的服务条款。"

    params = %{
      "content" => updated_content
    }

    {:ok, term2} = update_term(term1, params)

    assert term2.content == updated_content
  end
end
