defmodule PolicrMini.CustomKitBusiness do
  @moduledoc """
  自定义验证套件的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.CustomKit

  import Ecto.Query, only: [from: 2]

  @type writed_result :: {:ok, CustomKit.t()} | {:error, Ecto.Changeset.t()}

  @max_count 55

  @spec create(map()) :: writed_result | {:error, %{description: String.t()}}
  def create(params) do
    chat_id = params[:chat_id] || params["chat_id"]

    if PolicrMini.Chats.get_custom_kits_count(chat_id) >= @max_count do
      {:error, %{description: "自定义问答已达到数量上限"}}
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
  def find_list(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    from(c in CustomKit, where: c.chat_id == ^chat_id) |> Repo.all()
  end

  def random_one(chat_id) do
    from(c in CustomKit, where: c.chat_id == ^chat_id, order_by: fragment("RANDOM()"), limit: 1)
    |> Repo.one()
  end
end
