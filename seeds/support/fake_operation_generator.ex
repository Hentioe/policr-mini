alias PolicrMini.Chats.Operation

defmodule PolicrMini.Seeds.Support.FakeOperationGenerator do
  def generate(chat_id, verification_id, stop_secs) when is_integer(stop_secs) do
    # 随机生成动作
    action = Enum.random([:kick, :ban, :unban, :verify])
    # 随机生成角色
    role = Enum.random([:system, :admin])
    # 随机创建截止时间前至今的时间戳
    timestamp =
      DateTime.utc_now() |> DateTime.add(-:rand.uniform(stop_secs), :second)

    params = %{
      chat_id: chat_id,
      verification_id: verification_id,
      action: action,
      role: role,
      inserted_at: timestamp,
      updated_at: timestamp
    }

    fields =
      Operation.required_fields() ++
        Operation.optional_fields() ++ [:inserted_at, :updated_at]

    {:ok, _} =
      %Operation{}
      |> Ecto.Changeset.cast(params, fields)
      |> PolicrMini.Repo.insert()
  end
end
