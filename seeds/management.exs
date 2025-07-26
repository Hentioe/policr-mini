alias PolicrMini.Uses
alias PolicrMini.Seeds.Support.FakeChatGenerator

# 生成 10,000 个群组
for i <- 1..10_000 do
  {:ok, chat} = Uses.add_chat(FakeChatGenerator.generate_params(i))
end
