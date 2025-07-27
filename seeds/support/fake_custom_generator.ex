defmodule PolicrMini.Seeds.Support.FakeCustomGenerator do
  def generate_all(chat_id) do
    customs = [
      %{
        chat_id: chat_id,
        title: "这副画作出自那位艺术家？",
        answers: ["+梵高", "-毕加索", "-达芬奇", "-米开朗基罗"],
        attachment: "photo/xxxxxxxxxxxxxxxxx"
      },
      %{
        chat_id: chat_id,
        title: "以下哪个城市不属于德国？",
        answers: ["+巴黎", "-柏林", "-慕尼黑", "-法兰克福"]
      },
      %{
        chat_id: chat_id,
        title: "哪个元素在元素周期表中是惰性气体？",
        answers: ["+氖", "-氧", "-氮", "-氢"]
      },
      %{
        chat_id: chat_id,
        title: "莎士比亚的四大悲剧不包括以下哪一部？",
        answers: ["+仲夏夜之梦", "-哈姆雷特", "-奥赛罗", "-李尔王"]
      },
      %{
        chat_id: chat_id,
        title: "以下哪项是计算机的中央处理器（CPU）的主要功能？",
        answers: ["+执行指令", "-存储数据", "-显示图像", "-打印文档"]
      },
      %{
        chat_id: chat_id,
        title: "光合作用的主要产物是什么？",
        answers: ["+葡萄糖和氧气", "-二氧化碳和水", "-氮气和氢气", "-淀粉和水"]
      }
    ]

    for params <- customs do
      {:ok, _} = PolicrMini.Chats.add_custom(params)
    end
  end
end
