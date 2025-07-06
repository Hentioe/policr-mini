defmodule PolicrMini.CapindeTest do
  use ExUnit.Case

  import PolicrMini.Capinde
  alias PolicrMini.Capinde.{Input, Generated}

  test "generate/1" do
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
  end
end
