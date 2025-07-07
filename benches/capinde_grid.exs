alias PolicrMini.Capinde
alias PolicrMini.Capinde.Input

input = %Input{
  namespace: "out",
  ttl_secs: 5,
  special_params: %Input.GridParams{
    cell_width: 180,
    cell_height: 120,
    watermark_font_family: "Open Sans",
    right_count: 3,
    with_choices: true,
    choices_count: 9,
    unordered_right_parts: true
  }
}

Benchee.run(%{
  "generate/grid" => fn ->
    {:ok, generated} = Capinde.generate(input)
  end
})
