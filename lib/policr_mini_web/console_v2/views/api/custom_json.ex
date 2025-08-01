defmodule PolicrMiniWeb.ConsoleV2.API.CustomView do
  use PolicrMiniWeb, :view
  use PolicrMiniWeb.ConsoleV2.Helpers, :view

  alias PolicrMini.Chats.CustomKit

  def render("show.json", %{custom: custom}) do
    success(render("custom.json", %{custom: custom}))
  end

  def render("custom.json", %{custom: custom}) when is_struct(custom, CustomKit) do
    %{
      id: custom.id,
      title: custom.title,
      answers: Enum.map(custom.answers, &render_answer/1),
      attachment: custom.attachment,
      updated_at: custom.updated_at,
      inserted_at: custom.inserted_at
    }
  end

  def render_answer(answer) do
    correct = String.starts_with?(answer, "+")

    text =
      if correct do
        String.trim_leading(answer, "+")
      else
        String.trim_leading(answer, "-")
      end

    %{
      text: text,
      correct: correct
    }
  end
end
