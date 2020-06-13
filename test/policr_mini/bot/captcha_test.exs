defmodule PolicrMini.Bot.CaptchaTest do
  use ExUnit.Case

  import PolicrMini.Bot.Captcha

  alias Nadia.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

  test "build_markup/1" do
    markup =
      [
        [
          "猫",
          "狗",
          "猪"
        ]
      ]
      |> build_markup("v1", 100)

    assert markup == %InlineKeyboardMarkup{
             inline_keyboard: [
               [
                 %InlineKeyboardButton{text: "猫", callback_data: "verification:v1:100:1"},
                 %InlineKeyboardButton{text: "狗", callback_data: "verification:v1:100:2"},
                 %InlineKeyboardButton{text: "猪", callback_data: "verification:v1:100:3"}
               ]
             ]
           }

    markup =
      [
        [
          1,
          2,
          3
        ],
        [
          4,
          5,
          6
        ]
      ]
      |> build_markup("v1", 100)

    assert markup == %InlineKeyboardMarkup{
             inline_keyboard: [
               [
                 %InlineKeyboardButton{text: "1", callback_data: "verification:v1:100:1"},
                 %InlineKeyboardButton{text: "2", callback_data: "verification:v1:100:2"},
                 %InlineKeyboardButton{text: "3", callback_data: "verification:v1:100:3"}
               ],
               [
                 %InlineKeyboardButton{text: "4", callback_data: "verification:v1:100:4"},
                 %InlineKeyboardButton{text: "5", callback_data: "verification:v1:100:5"},
                 %InlineKeyboardButton{text: "6", callback_data: "verification:v1:100:6"}
               ]
             ]
           }
  end
end
