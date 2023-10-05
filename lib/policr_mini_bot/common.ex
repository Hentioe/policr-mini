defmodule PolicrMiniBot.Common do
  @moduledoc false

  use PolicrMini.I18n

  # TODO: 精简此处的函数名。
  @spec non_super_group_message :: {String.t(), String.t()}
  def non_super_group_message do
    ttitle = commands_text("请在超级群中使用本机器人")

    tdesc = commands_text("将本群升级为超级群以后，可再次添加本机器人。如果您正在实施测试，请在测试完成后将本机器人移出群组。")

    tcomment = commands_text("提示：如果您不清楚普通群、超级群这些概念，请尝试为本群创建公开链接。创建公开链接后再转私有的群仍然是超级群。")

    text = """
    <b>#{ttitle}</b>

    #{tdesc}

    <i>#{tcomment}</i>
    """

    {"HTML", text}
  end
end
