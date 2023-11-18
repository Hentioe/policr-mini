assets_path = Path.join("test", "assets")

Benchee.run(%{
  "PolicrMini.ImgCore.rewrite_image/2" => fn ->
    PolicrMini.ImgCore.rewrite_image(
      Path.join(assets_path, "white-180x120.jpg"),
      Path.join(assets_path, "output")
    )
  end
})
