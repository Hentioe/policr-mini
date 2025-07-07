defmodule PolicrMiniBot.ImageCAPTCHA do
  @moduledoc """
  图片验证。
  """

  use PolicrMiniBot.Captcha

  alias PolicrMini.Capinde
  alias PolicrMini.Capinde.Input

  defmodule Error do
    defexception [:message]
  end

  @impl true
  def make!(_chat_id, scheme) do
    choices_count = scheme.image_answers_count || PolicrMiniBot.Helper.default!(:acimage)

    input =
      %Input{
        namespace: "out",
        ttl_secs: 35,
        special_params: %Input.ImageParams{
          dynamic_digest: PolicrMini.opt_exists?("--disable-image-rewrite"),
          with_choices: true,
          choices_count: choices_count
        }
      }

    case Capinde.generate(input) do
      {:ok, generated} ->
        # 生成候选项
        candidates =
          Enum.map(generated.special_payload.choices, fn choice -> [choice["zh-hans"]] end)

        # 为 right_indexes 中的每一项自增一
        right_indexes = Enum.map(generated.special_payload.right_indexes, fn i -> i + 1 end)

        %Captcha.Data{
          question: "图片中的事物是？",
          photo: Path.join("shared_assets", generated.file_name),
          candidates: candidates,
          correct_indices: right_indexes
        }

      {:error, %{message: message}} ->
        raise Error, message: message

      {:error, reason} ->
        raise Error, message: "Failed to generate image CAPTCHA: #{inspect(reason)}"
    end
  end
end
