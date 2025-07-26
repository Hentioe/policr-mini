defmodule PolicrMini.Seeds.Support.FakeChatGenerator do
  # 中文词库：形容词
  @adjectives [
    "快乐的",
    "有趣的",
    "热情的",
    "专业的",
    "活跃的",
    "温暖的",
    "创新的",
    "友好的",
    "轻松的",
    "激情的",
    "独特的",
    "开放的",
    "多元的",
    "热闹的",
    "和谐的",
    "精彩的",
    "充满活力的",
    "真诚的",
    "轻松的",
    "欢乐的"
  ]

  # 中文词库：名词
  @nouns [
    "朋友",
    "聊天",
    "聚会",
    "兴趣",
    "学习",
    "工作",
    "娱乐",
    "音乐",
    "电影",
    "旅行",
    "美食",
    "运动",
    "科技",
    "游戏",
    "分享",
    "讨论",
    "创意",
    "梦想",
    "冒险",
    "生活",
    "健康",
    "编程",
    "设计",
    "艺术",
    "文化",
    "未来",
    "社区",
    "团队",
    "合作",
    "灵感",
    "成长",
    "探索",
    "交流",
    "知识",
    "青春",
    "故事"
  ]
  # 英文词库：用于生成用户名
  @english_words [
    "chat",
    "group",
    "community",
    "crypto",
    "tech",
    "music",
    "game",
    "art",
    "travel",
    "food",
    "sport",
    "code",
    "design",
    "movie",
    "life",
    "dream",
    "share",
    "talk",
    "idea",
    "fun",
    "learn",
    "work",
    "team",
    "grow",
    "explore",
    "create",
    "future",
    "vibe",
    "connect",
    "spark",
    "quest",
    "journey",
    "hub",
    "space",
    "circle"
  ]

  def generate_title do
    # 生成 5-15 个字的标题（2-4 个词）
    word_count = Enum.random(2..4)
    words = Enum.take_random(@adjectives ++ @nouns, word_count)
    title = Enum.join(words, "")
    # 确保标题长度在 5-15 字
    String.slice(title, 0, 15)
  end

  def generate_description do
    # 生成 10-35 个字的描述（5-10 个词）
    word_count = Enum.random(5..10)
    words = Enum.take_random(@adjectives ++ @nouns, word_count)
    description = Enum.join(words, " ")
    # 确保描述长度在 10-35 字
    String.slice(description, 0, 35)
  end

  def generate_username do
    # 1/3 概率生成单个单词，1/3 概率生成两个单词用下划线连接，1/3 概率生成空
    case Enum.random(1..3) do
      1 ->
        Enum.random(@english_words)

      2 ->
        word1 = Enum.random(@english_words)
        # 避免重复单词
        word2 = Enum.random(@english_words -- [word1])
        "#{word1}_#{word2}"

      _ ->
        nil
    end
  end

  def generate_params(id) do
    # 随机生成接管状态
    is_take_over = Enum.random([true, false])
    # 随机生成离开状态
    left = Enum.random([true, false, nil])

    params = %{
      id: id,
      type: :supergroup,
      title: generate_title(),
      description: generate_description(),
      username: generate_username(),
      is_take_over: is_take_over,
      left: left
    }
  end
end
