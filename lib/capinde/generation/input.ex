defmodule Capinde.Generation.Input do
  @moduledoc false

  @derive JSON.Encoder

  use TypedStruct

  typedstruct module: GridParams do
    @derive JSON.Encoder

    field :type, String.t(), default: "grid"
    field :layout, String.t(), enforce: true
    field :cell_width, integer(), enforce: true
    field :cell_height, integer(), enforce: true
    field :watermark_font_family, String.t(), enforce: true
    field :watermark_font_size, integer()
    field :watermark_font_weight, float()
    field :right_count, integer()
    field :unordered_right_parts, boolean()
  end

  typedstruct module: ImageParams do
    @derive JSON.Encoder

    field :type, String.t(), default: "image"
    field :dynamic_digest, boolean()
  end

  typedstruct module: ClassicParams do
    @derive JSON.Encoder

    field :type, String.t(), default: "classic"
    field :length, integer()
    field :width, integer()
    field :height, integer()
    field :dark_mode, boolean()
    field :complexity, integer()
    field :compression, integer()
  end

  @type special_params :: GridParams.t() | ImageParams.t() | ClassicParams.t()

  typedstruct do
    field :namespace, String.t(), enforce: true
    field :ttl_secs, integer()
    field :use_index, boolean()
    field :with_choices, boolean()
    field :choices_count, integer()
    field :special_params, special_params()
  end
end
