alias PolicrMini.Stats
alias PolicrMini.Stats.WritePoint

chat_id = String.to_integer("-1001486769003")
user_id = String.to_integer("340396281")

# 生成最近一周的 70 条随机验证数据点
for i <- 1..70 do
  status = Enum.random([:passed, :rejected, :timeout, :other])
  dt = DateTime.utc_now() |> DateTime.add(-1 * Enum.random(0..6), :day)
  source = Enum.random([:joined, :join_request])

  point = %WritePoint{
    measurement: "verifications",
    fields: %{
      count: 1
    },
    tags: %{
      chat_id: chat_id,
      user_id: user_id,
      status: to_string(status),
      source: to_string(source)
    },
    timestamp: dt
  }

  Stats.write(point)
end
