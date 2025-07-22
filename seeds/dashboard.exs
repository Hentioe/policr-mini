alias PolicrMini.{Accounts, Uses}
alias PolicrMini.Chats.Verification

# 生成一个基础群组
{:ok, chat} = Uses.add_chat(%{id: 1, type: :supergroup, is_take_over: true})
# 生成一个基础用户
{:ok, user} = Accounts.add_user(%{id: 1, token_ver: 0})

# 生成 10,000 个验证记录
for i <- 1..10_000 do
  # 随机生成状态
  status = Enum.random([:passed, :timeout, :wronged, :expired, :manual_kick, :manual_ban])
  # 随机创建 4 年前至今的时间戳
  timestamp = DateTime.utc_now() |> DateTime.add(-:rand.uniform(4 * 365 * 24 * 60 * 60), :second)

  params = %{
    chat_id: chat.id,
    target_user_id: user.id,
    seconds: 60,
    status: status,
    source: :joined,
    inserted_at: timestamp,
    updated_at: timestamp
  }

  %Verification{}
  |> Ecto.Changeset.cast(params, Verification.required_fields() ++ [:inserted_at, :updated_at])
  |> PolicrMini.Repo.insert()
end
