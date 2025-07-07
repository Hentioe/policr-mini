defmodule PolicrMiniBot.ClassicCAPTCHA do
  @moduledoc """
  经典验证：传统验证码。
  """

  use PolicrMiniBot.Captcha

  alias PolicrMini.Capinde
  alias PolicrMini.Capinde.Input

  defmodule Error do
    defexception [:message]
  end

  @impl true
  def make!(_chat_id, _scheme) do
    input = %Input{
      namespace: "out",
      ttl_secs: 35,
      special_params: %Input.ClassicParams{
        length: 5,
        width: 320,
        height: 120,
        dark_mode: false,
        complexity: 10,
        with_choices: true,
        choices_count: 9
      }
    }

    case Capinde.generate(input) do
      {:ok, generated} ->
        correct_index =
          Enum.find_index(generated.special_payload.choices, fn choice ->
            choice == generated.special_payload.text
          end)

        %Captcha.Data{
          question: "请选择验证码图片中的文字",
          photo: Path.join("shared_assets", generated.file_name),
          candidates: Enum.chunk_every(generated.special_payload.choices, 3),
          correct_indices: [correct_index + 1]
        }

      {:error, %{message: message}} ->
        raise Error, message: message

      {:error, reason} ->
        raise Error, message: "Failed to generate classic CAPTCHA: #{inspect(reason)}"
    end
  end
end
