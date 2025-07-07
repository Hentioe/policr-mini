defmodule PolicrMiniBot.GridCAPTCHA do
  @moduledoc """
  网格验证：用图集素材生成九宫格一类的图片。
  """

  use PolicrMiniBot.Captcha

  alias PolicrMini.Capinde
  alias PolicrMini.Capinde.Input

  defmodule Error do
    defexception [:message]
  end

  @right_count 3
  @choices_count 9
  @watermark_font_family "Open Sans"

  @impl true
  def make!(_chat_id, _scheme) do
    cell_width = config_get(:indi_width, 180)
    cell_height = config_get(:indi_height, 120)
    watermark_font_family = config_get(:watermark_font_family, @watermark_font_family)

    input = %Input{
      namespace: "out",
      ttl_secs: 35,
      special_params: %Input.GridParams{
        cell_width: cell_width,
        cell_height: cell_height,
        watermark_font_family: watermark_font_family,
        right_count: @right_count,
        with_choices: true,
        choices_count: @choices_count,
        unordered_right_parts: true
      }
    }

    case Capinde.generate(input) do
      {:ok, generated} ->
        subject_name = generated.special_payload.subject["zh-hans"]
        candidates = Enum.map(generated.special_payload.choices, &Enum.join/1)

        correct_index =
          Enum.find_index(generated.special_payload.choices, fn choice ->
            choice == generated.special_payload.right_parts
          end) + 1

        %Captcha.Data{
          question: "选出所有「#{subject_name}」的图片编号",
          photo: Path.join("shared_assets", generated.file_name),
          candidates: Enum.chunk_every(candidates, 3),
          correct_indices: [correct_index]
        }

      {:error, %{message: message}} ->
        raise Error, message: message

      {:error, reason} ->
        raise Error, message: "Failed to generate grid CAPTCHA: #{inspect(reason)}"
    end
  end

  defp config_get(key, default) do
    Application.get_env(:policr_mini, __MODULE__)[key] || default
  end
end
