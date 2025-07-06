alias PolicrMini.Capinde
alias PolicrMini.Capinde.Input

input = %Input{
  namespace: "out",
  ttl_secs: 5,
  special_params: %Input.ImageParams{
    dynamic_digest: true,
    with_choices: true,
    choices_count: 5
  }
}

Benchee.run(%{
  "generate/image" => fn ->
    {:ok, generated} = Capinde.generate(input)
  end
})
