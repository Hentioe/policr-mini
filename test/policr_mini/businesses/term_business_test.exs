defmodule PolicrMini.TermBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.TermBusiness

  def build_params(attrs \\ []) do
    term = Factory.build(:term)

    term
    |> struct(attrs)
    |> Map.from_struct()
  end

  test "create/1" do
    term_params = build_params()
    {:ok, term} = TermBusiness.create(term_params)

    assert term.id == term_params.id
    assert term.content == term_params.content
  end

  test "update/2" do
    term_params = build_params()
    {:ok, term1} = TermBusiness.create(term_params)

    updated_content = "更新后的服务条款。"

    params = %{
      "content" => updated_content
    }

    {:ok, term2} = term1 |> TermBusiness.update(params)

    assert term2.content == updated_content
  end
end
