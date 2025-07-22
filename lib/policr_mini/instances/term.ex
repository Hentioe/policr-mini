defmodule PolicrMini.Instances.Term do
  @moduledoc false

  use PolicrMini.Schema

  @required_fields ~w(id)a
  @optional_fields ~w(content)a

  @primary_key {:id, :integer, autogenerate: false}
  schema "terms" do
    field :content, :string

    timestamps()
  end

  def changeset(module, attrs) when is_struct(module, __MODULE__) and is_map(attrs) do
    module
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def as_html_message(term) when is_struct(term, __MODULE__) do
    """
    <b>📜 机器人使用条款</b>

    #{Telegex.Tools.safe_html(term.content)}

    <i>若您不同意本条款，请点击「不同意」按钮让机器人自行离开。</i>
    """
  end

  @spec default :: __MODULE__.t()
  def default do
    %__MODULE__{
      id: 1,
      content: nil
    }
  end
end
