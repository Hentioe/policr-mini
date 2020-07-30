defmodule PolicrMini.CustomKitBusiness do
  @moduledoc """
  自定义验证套件的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schemas.CustomKit

  import Ecto.Query, only: [from: 2, dynamic: 2]

  @type writed_result :: {:ok, CustomKit.t()} | {:error, Ecto.Changeset.t()}

  @max_count 12

  @spec create(map()) :: writed_result | {:error, %{description: String.t()}}
  def create(params) do
    chat_id = params[:chat_id] || params["chat_id"]

    if find_count(chat_id: chat_id) >= @max_count do
      {:error, %{description: "the total number of custom kits has reached the upper limit"}}
    else
      %CustomKit{} |> CustomKit.changeset(params) |> Repo.insert()
    end
  end

  def update(%CustomKit{} = custom_kit, params) do
    custom_kit |> CustomKit.changeset(params) |> Repo.update()
  end

  def delete(%CustomKit{} = custom_kit) do
    custom_kit |> Repo.delete()
  end

  @spec find_list(integer) :: [CustomKit.t()]
  def find_list(chat_id) when is_integer(chat_id) do
    from(c in CustomKit, where: c.chat_id == ^chat_id) |> Repo.all()
  end

  def random_one(chat_id) when is_integer(chat_id) do
    from(c in CustomKit, where: c.chat_id == ^chat_id, order_by: fragment("RANDOM()"), limit: 1)
    |> Repo.one()
  end

  @type find_count_opts :: [{:chat_id, integer()}]

  # TODO: 添加测试
  @spec find_count(any) :: integer()
  def find_count(options \\ []) do
    filter_chat_id =
      if chat_id = Keyword.get(options, :chat_id),
        do: dynamic([c], c.chat_id == ^chat_id),
        else: true

    from(c in CustomKit, select: count(c.id), where: ^filter_chat_id) |> Repo.one()
  end
end
