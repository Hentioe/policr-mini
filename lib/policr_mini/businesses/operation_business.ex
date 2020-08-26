defmodule PolicrMini.OperationBusiness do
  @moduledoc """
  操作的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schemas.Operation

  # alias PolicrMini.EctoEnums.{OperationActionEnum, OperationRoleEnum}

  # import Ecto.Query, only: [from: 2, dynamic: 2]

  @typep written_returns :: {:ok, Operation.t()} | {:error, Ecto.Changeset.t()}

  # TODO：添加测试。
  @doc """
  创建操作记录。
  """
  @spec create(PolicrMini.Schema.params()) :: written_returns
  def create(params) do
    %Operation{} |> Operation.changeset(params) |> Repo.insert()
  end

  @type find_list_cont :: [
          {:offset, integer},
          {:limit, integer},
          {:action, :kick | :ban},
          {:role, :system | :admin}
        ]

  # TODO：添加测试。
  @doc """
  查询操作列表。
  """
  @spec find_list(find_list_cont) :: [Operation.t()]
  def find_list(_cont \\ []) do
    # TODO：实现这里。
    []
  end
end
