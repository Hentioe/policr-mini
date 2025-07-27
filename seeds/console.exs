alias PolicrMini.Repo
alias PolicrMini.{Accounts, Uses, Chats}
alias PolicrMini.Seeds.Support.{FakeChatGenerator, FakeCustomGenerator, FakeVerificationGenerator}

# 在生成前清空数据
Repo.delete_all(PolicrMini.Schema.Permission)
Repo.delete_all(PolicrMini.Schema.User)
Repo.delete_all(PolicrMini.Chats.CustomKit)
Repo.delete_all(PolicrMini.Chats.Operation)
Repo.delete_all(PolicrMini.Chats.Verification)
Repo.delete_all(PolicrMini.Instances.Chat)

# 创建基础用户
{:ok, user} =
  Accounts.upsert_user(111_111_111, %{
    token_ver: 0,
    first_name: "Admin Dev",
    photo:
      "https://cdn5.cdn-telegram.org/file/Eajdq1IthZDo-eJj2hqwtZDFCJ8c9TuElwyH9Vs8iS79NRWg2Eur5_NM8SXx4TpB2CjWxVsHvtab39RBdMP4JGube5JaD5XpdwOVjOst9k6LVsApdOM-JAUA-cHoxVsP68pqCMwKJyBV4zYe0xI_Dlb6Qx0FNmE_3KUZ_gAxRghRfPtRpEdJlnvqseS1bNiicZsdnQonp95ccziuYFX2xboIC3EiQ0GOvhgJGg1HCuvF2QvlaEozdwq-kr_embKCZTEGMzegxpZ_sLNGXRlMW27a_09ydRiv6HrDtd0dDTZ7C1EWM3DJJTn29kNQm4K0QBFA_ibO6R0erj6JvGC9Hw.jpg"
  })

# 创建群组、用户权限、自定义数据
for i <- 1..10 do
  {:ok, chat} = Uses.add_chat(FakeChatGenerator.generate_params(i))

  {:ok, _} =
    Chats.add_permission(%{
      chat_id: chat.id,
      user_id: user.id,
      tg_can_restrict_members: true,
      readable: true,
      writable: true,
      tg_is_owner: true
    })

  FakeCustomGenerator.generate_all(chat.id)
  FakeVerificationGenerator.generate_all_with_operations(chat.id, user, 3600 * 24 * 30)
end
