defmodule PolicrMiniWeb.AdminV2.API.TermController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Settings
  alias PolicrMini.Instances.Term

  import PolicrMiniWeb.AdminV2.ViewHelper, only: [success: 0, failure: 1]

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  def show(conn, _params) do
    term = Settings.get_term() || Term.default()
    render(conn, "show.json", %{term: term})
  end

  def save(conn, %{"content" => content} = _params) do
    with {:ok, term} <- Settings.upsert_term(content) do
      render(conn, "show.json", %{term: term})
    end
  end

  def delete(conn, _params) do
    with {:ok, term} <- Settings.delete_term() do
      render(conn, "show.json", %{term: term})
    end
  end

  def preview(conn, %{"content" => content} = _params) when content == "" do
    json(conn, failure("内容不能为空"))
  end

  def preview(conn, %{"content" => content} = _params) do
    alias Telegex.Type.{InlineKeyboardMarkup, InlineKeyboardButton}

    text = Term.as_html_message(%Term{content: content})

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "同意",
            callback_data: "term:v1:preview:agree"
          },
          %InlineKeyboardButton{
            text: "不同意",
            callback_data: "term:v1:preview:disagree"
          }
        ]
      ]
    }

    owner_id = PolicrMiniBot.config_get(:owner_id)

    with {:ok, _} <-
           Telegex.send_message(owner_id, text, reply_markup: markup, parse_mode: "HTML") do
      json(conn, success())
    end
  end
end
