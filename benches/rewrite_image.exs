assets_path = Path.join("test", "assets")

Benchee.run(%{
  "PolicrMini.ImgKit.rewrite_image/2" => fn ->
    PolicrMini.ImgKit.rewrite_image(
      Path.join(assets_path, "white-180x120.jpg"),
      Path.join(assets_path, "output")
    )
  end
})
