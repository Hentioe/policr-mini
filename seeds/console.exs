alias PolicrMini.Accounts

# 创建基础用户
{:ok, _} =
  Accounts.upsert_user(111_111_111, %{
    token_ver: 0,
    first_name: "Admin Dev",
    photo:
      "https://cdn5.cdn-telegram.org/file/Eajdq1IthZDo-eJj2hqwtZDFCJ8c9TuElwyH9Vs8iS79NRWg2Eur5_NM8SXx4TpB2CjWxVsHvtab39RBdMP4JGube5JaD5XpdwOVjOst9k6LVsApdOM-JAUA-cHoxVsP68pqCMwKJyBV4zYe0xI_Dlb6Qx0FNmE_3KUZ_gAxRghRfPtRpEdJlnvqseS1bNiicZsdnQonp95ccziuYFX2xboIC3EiQ0GOvhgJGg1HCuvF2QvlaEozdwq-kr_embKCZTEGMzegxpZ_sLNGXRlMW27a_09ydRiv6HrDtd0dDTZ7C1EWM3DJJTn29kNQm4K0QBFA_ibO6R0erj6JvGC9Hw.jpg"
  })
