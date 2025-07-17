defmodule Capinde.Payload.ServerInfo do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field :version, String.t(), enforce: true
    field :working_mode, String.t(), enforce: true
    field :started_at, DateTime.t()
    field :verification_queue_length, integer(), enforce: true
  end

  def from(%{
        "version" => version,
        "working_mode" => working_mode,
        "started_at" => started_at,
        "verification_queue_length" => verification_queue_length
      }) do
    started_at =
      with false <- is_nil(started_at),
           {:ok, started_at, _} <- DateTime.from_iso8601(started_at) do
        started_at
      else
        _ ->
          nil
      end

    %__MODULE__{
      version: version,
      working_mode: working_mode,
      started_at: started_at,
      verification_queue_length: verification_queue_length
    }
  end
end
