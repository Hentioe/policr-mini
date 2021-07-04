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
    is_highlighted: true,
    mention_text: :mosaic_full_name,
    image_answers_count: 4
  }

  @doc """
  获取默认方案，如果不存在将自动创建。
  """
  @spec fetch_default :: written_returns
  def fetch_default do
    Repo.transaction(fn ->
      case find(@default_id) || create_default(@default_scheme) do
        {:ok, scheme} ->
          # 创建了一个新的方案。
          scheme

        {:error, e} ->
          # 创建方案发生错误。
          Repo.rollback(e)

        scheme ->
          # 方案已存在。
          fill_default_in_transaction(scheme)
      end
    end)
  end

  @spec fill_default_in_transaction(Scheme.t()) :: Scheme.t() | no_return
  defp fill_default_in_transaction(scheme) do
    attrs = %{}

    # 此处填充后续在方案中添加的新字段，避免方案已存在时这些字段出现 `nil` 值。
    attrs = if scheme.mention_text, do: attrs, else: %{mention_text: @default_scheme.mention_text}

    attrs =
      if scheme.image_answers_count,
        do: attrs,
        else: %{image_answers_count: @default_scheme.image_answers_count}

    case update(scheme, attrs) do
      {:ok, scheme} -> scheme
      {:error, e} -> Repo.rollback(e)
    end
  end
end
