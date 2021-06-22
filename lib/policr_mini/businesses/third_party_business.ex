defmodule PolicrMini.ThirdPartyBusiness do
  @moduledoc """
  第三方实例的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.ThirdParty

  import Ecto.Query, only: [from: 2]

  @type written_returns :: {:ok, ThirdParty.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map) :: written_returns
  def create(params) do
    %ThirdParty{} |> ThirdParty.changeset(params) |> Repo.insert()
  end

  @spec update(ThirdParty.t(), map) :: written_returns
  def update(third_party, params) do
    third_party |> ThirdParty.changeset(params) |> Repo.update()
  end

  def delete(third_party) when is_struct(third_party, ThirdParty) do
    Repo.delete(third_party)
  end

  @spec find_list(keyword) :: [ThirdParty.t()]
  def find_list(_find_list_conts \\ []) do
    from(t in ThirdParty, order_by: [desc: t.running_days])
    |> Repo.all()
  end

  @doc """
  重置运行天数为零。
  """
  @spec reset_running_days(ThirdParty.t()) :: written_returns
  def reset_running_days(third_party) do
    update(third_party, %{running_days: 0})
  end
end
