alias PolicrMini.Capinde
alias PolicrMini.Capinde.Input

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

Benchee.run(%{
  "generate/classic" => fn ->
    {:ok, generated} = Capinde.generate(input)
  end
})
