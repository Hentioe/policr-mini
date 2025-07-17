defmodule Capinde.Payload.ArchiveInfo do
  @moduledoc false

  alias Capinde.Payload.Manifest

  use TypedStruct

  typedstruct do
    field :manifest, Manifest.t(), enforce: true
    field :total_images, integer(), enforce: true
  end

  def from(%{"manifest" => manifest, "total_images" => total_images}) do
    %__MODULE__{
      manifest: Manifest.from(manifest),
      total_images: total_images
    }
  end
end
