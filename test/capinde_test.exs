defmodule CapindeTest do
  use ExUnit.Case

  import Capinde

  alias Capinde.Generation.Input
  alias Capinde.Payload.Generated

  test "generate/1 with grid" do
    input = %Input{
      namespace: "out",
      ttl_secs: 5,
      with_choices: true,
      choices_count: 9,
      special_params: %Input.GridParams{
        layout: "3x3",
        cell_width: 180,
        cell_height: 120,
        watermark_font_family: "Open Sans",
        right_count: 3,
        unordered_right_parts: true
      }
    }

    {:ok, generated} = generate(input)

    assert is_struct(generated, Generated)
    assert is_struct(generated.special_payload, Generated.GridPayload)
    assert generated.special_payload.type == "grid"
    assert length(generated.special_payload.choices) == 9

    for choice <- generated.special_payload.choices do
      assert length(choice) == 3
    end
  end

  test "generate/1 with image" do
    input = %Input{
      namespace: "out",
      ttl_secs: 5,
      with_choices: true,
      choices_count: 5,
      special_params: %Input.ImageParams{
        dynamic_digest: true
      }
    }

    {:ok, generated} = generate(input)

    assert is_struct(generated, Generated)
    assert is_struct(generated.special_payload, Generated.ImagePayload)
    assert length(generated.special_payload.choices) == 5
    assert generated.special_payload.type == "image"
  end

  test "generate/1 with classic" do
    input = %Input{
      namespace: "out",
      ttl_secs: 5,
      with_choices: true,
      choices_count: 9,
      special_params: %Input.ClassicParams{
        length: 5,
        width: 160,
        height: 60,
        dark_mode: false,
        complexity: 10
      }
    }

    {:ok, generated} = generate(input)

    assert is_struct(generated, Generated)
    assert is_struct(generated.special_payload, Generated.ClassicPayload)
    assert length(generated.special_payload.choices) == 9
    assert generated.special_payload.type == "classic"
    # 选项中包含正确答案
    assert Enum.member?(generated.special_payload.choices, generated.special_payload.text)
  end
end
