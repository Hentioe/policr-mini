defmodule PolicrMiniBot.CaptchaTest do
  use ExUnit.Case

  import PolicrMiniBot.Captcha

  alias Telegex.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

  test "build_markup/1" do
    markup =
      build_markup(
        [
          ["猫", "狗", "猪"]
        ],
        100
      )

    assert markup == %InlineKeyboardMarkup{
             inline_keyboard: [
               [
                 %InlineKeyboardButton{text: "猫", callback_data: "ans:v1:1:100"},
                 %InlineKeyboardButton{text: "狗", callback_data: "ans:v1:2:100"},
                 %InlineKeyboardButton{text: "猪", callback_data: "ans:v1:3:100"}
               ]
             ]
           }

    markup =
      build_markup(
        [
          [1, 2, 3],
          [4, 5, 6]
        ],
        100
      )

    assert markup == %InlineKeyboardMarkup{
             inline_keyboard: [
               [
                 %InlineKeyboardButton{text: "1", callback_data: "ans:v1:1:100"},
                 %InlineKeyboardButton{text: "2", callback_data: "ans:v1:2:100"},
                 %InlineKeyboardButton{text: "3", callback_data: "ans:v1:3:100"}
               ],
               [
                 %InlineKeyboardButton{text: "4", callback_data: "ans:v1:4:100"},
                 %InlineKeyboardButton{text: "5", callback_data: "ans:v1:5:100"},
                 %InlineKeyboardButton{text: "6", callback_data: "ans:v1:6:100"}
               ]
             ]
           }
  end
end
