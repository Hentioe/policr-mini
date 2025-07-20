defmodule PolicrMiniWeb.AdminV2.API.SchemeView do
  use PolicrMiniWeb, :admin_v2_view

  def render("scheme.json", %{scheme: scheme}) do
    %{
      type: scheme.verification_mode,
      type_items: type_items(),
      timeout: scheme.seconds,
      kill_strategy: scheme.wrong_killing_method,
      fallback_kill_strategy: scheme.timeout_killing_method,
      kill_strategy_items: kill_strategy_items(),
      mention_text: scheme.mention_text,
      mention_text_items: mention_text_items(),
      image_choices_count: scheme.image_answers_count,
      image_choices_count_items: image_choices_count_items(),
      cleanup_messages: fix_cleanup_messages(scheme.service_message_cleanup),
      delay_unban_secs: scheme.delay_unban_secs
    }
  end

  defp type_items do
    [
      build_select_item("grid", "网格验证"),
      build_select_item("image", "图片验证"),
      build_select_item("custom", "定制验证（自定义）"),
      build_select_item("classic", "经典验证（传统验证码）"),
      build_select_item("arithmetic", "算术验证"),
      build_select_item("initiative", "后备验证")
    ]
  end

  defp kill_strategy_items do
    [
      build_select_item("kick", "踢出（封禁在延迟解封）"),
      build_select_item("ban", "封禁")
    ]
  end

  defp mention_text_items do
    [
      build_select_item("user_id", "用户 ID"),
      build_select_item("full_name", "用户全名"),
      build_select_item("mosaic_full_name", "马赛克全名")
    ]
  end

  defp image_choices_count_items do
    [
      build_select_item("3", "3"),
      build_select_item("4", "4"),
      build_select_item("5", "5")
    ]
  end

  def fix_cleanup_messages(message_cleanup) when is_list(message_cleanup) do
    Enum.map(message_cleanup, fn
      :lefted -> :left
      other -> other
    end)
  end

  defp build_select_item(value, label) do
    %{value: value, label: label}
  end
end
