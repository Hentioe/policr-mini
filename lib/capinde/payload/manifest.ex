defmodule Capinde.Payload.Manifest do
  @moduledoc false

  use TypedStruct

  defmodule Album do
    @moduledoc false

    typedstruct do
      field :id, String.t(), enforce: true
      field :name, %{String.t() => String.t()}, enforce: true
    end

    def from(%{"id" => id, "name" => name}) do
      %__MODULE__{
        id: id,
        name: name
      }
    end
  end

  typedstruct do
    field :version, String.t(), enforce: true
    field :datetime, DateTime.t(), enforce: true
    field :include_formats, [String.t(), ...], enforce: true
    field :albums, [Album.t(), ...], default: []
    field :conflicts, [[String.t(), ...]], default: []
  end

  def from(%{
        "version" => version,
        "datetime" => datetime,
        "include_formats" => include_formats,
        "albums" => albums
      }) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime)

    %__MODULE__{
      version: version,
      datetime: datetime,
      include_formats: include_formats,
      albums: Enum.map(albums, &Album.from/1)
    }
  end
end
