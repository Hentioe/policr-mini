defmodule PolicrMiniBot.ImageProviderTest do
  use ExUnit.Case

  alias PolicrMiniBot.ImageProvider.{Manifest, Album}

  test "Manifest.expand_albums_parents/1" do
    penguin = %Album{
      id: "企鹅",
      parents: ["哺乳动物"]
    }

    mammalian = %Album{
      id: "哺乳动物",
      parents: ["动物"]
    }

    animal = %Album{
      id: "动物",
      parents: ["生物"]
    }

    phoenix_tree = %Album{
      id: "梧桐树",
      parents: ["植物"]
    }

    plant = %Album{
      id: "植物",
      parents: ["生物"]
    }

    creature = %Album{
      id: "生物",
      parents: nil
    }

    manifest = %Manifest{
      albums: [penguin, mammalian, animal, phoenix_tree, plant, creature]
    }

    %{
      albums: [
        %{id: "企鹅", parents: ["哺乳动物", "动物", "生物"]},
        %{id: "哺乳动物", parents: ["动物", "生物"]},
        %{id: "动物", parents: ["生物"]},
        %{id: "梧桐树", parents: ["植物", "生物"]},
        %{id: "植物", parents: ["生物"]},
        %{id: "生物", parents: []} | _
      ]
    } = Manifest.expand_albums_parents(manifest)
  end
end
