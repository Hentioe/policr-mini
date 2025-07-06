defmodule PolicrMini.CapindeTest do
  use ExUnit.Case

  import PolicrMini.Capinde
  alias PolicrMini.Capinde.{Input, Generated}

  test "generate/1 with grid" do
    input = %Input{
      namespace: "out",
      ttl_secs: 5,
      special_params: %Input.GridParams{
        cell_width: 180,
        cell_height: 140,
        watermark_font_family: "Open Sans"
      }
    }

    {:ok, generated} = generate(input)

    assert is_struct(generated, Generated)
    assert is_struct(generated.special_payload, Generated.GridPayload)
    assert generated.special_payload.type == "grid"
  end

  test "generate/1 with image" do
    input = %Input{
      namespace: "out",
      ttl_secs: 5,
      special_params: %Input.ImageParams{
        dynamic_digest: true,
        with_choices: true,
        choices_count: 5
      }
    }

    {:ok, generated} = generate(input)

    assert is_struct(generated, Generated)
    assert is_struct(generated.special_payload, Generated.ImagePayload)
    assert length(generated.special_payload.choices) == 5
    assert generated.special_payload.type == "image"
  end
end
