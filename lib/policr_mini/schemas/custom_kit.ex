defmodule PolicrMini.Schemas.CustomKit do
  @moduledoc """
  自定义套件模型。
  """

  use PolicrMini.Schema

  alias PolicrMini.Schemas.Chat

  @required_fields ~w(chat_id title answers)a
  @optional_fields ~w(attachment)a

  schema "custom_kits" do
    belongs_to :chat, Chat

    field :title, :string
    field :answers, {:array, :string}
    field :attachment, :string

    timestamps()
  end

  @type t :: Ecto.Schema.t()

  def changeset(%__MODULE__{} = custom_kit, attrs) when is_map(attrs) do
    custom_kit
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_change(:answers, &validator/2)
    |> assoc_constraint(:chat)
  end

  @doc """
  检查 CustomKit 的相关字段是否有效的验证器。

  ## 可检查的字段
    - `answers`: 至少存在一个正确答案，即 `+` 开头的内容。

  ## 例子
      iex> PolicrMini.Schemas.CustomKit.validator(:answers, ["+正确答案", "-错误答案"])
      []
      iex> PolicrMini.Schemas.CustomKit.validator(:answers, ["无效的答案", "-错误答案"])
      [answers: "incorrect format"]
      iex> PolicrMini.Schemas.CustomKit.validator(:answers, ["-错误答案1", "-错误答案2"])
      [answers: "missing correct answer"]
  """
  @spec validator(atom, any) :: [{atom(), String.t()}]
  def validator(:answers, answers) when is_list(answers) do
    case check_answers(answers) do
      {:error, :incorrect_format} ->
        [answers: "incorrect format"]

      {:error, :missing_corrent} ->
        [answers: "missing correct answer"]

      :ok ->
        []
    end
  end

  @spec check_answers([String.t()]) :: :ok | {:error, :incorrect_format | :missing_corrent}
  defp check_answers(answers) when is_list(answers) do
    format_validity_fun = fn answer ->
      !(String.starts_with?(answer, "-") || String.starts_with?(answer, "+"))
    end

    invalid_answers = Enum.filter(answers, format_validity_fun)

    if length(invalid_answers) > 0 do
      {:error, :incorrect_format}
    else
      correct_answer_validity_fun = fn answer -> String.starts_with?(answer, "+") end
      correct_answer = Enum.find(answers, correct_answer_validity_fun)

      if correct_answer == nil do
        {:error, :missing_corrent}
      else
        :ok
      end
    end
  end
end
