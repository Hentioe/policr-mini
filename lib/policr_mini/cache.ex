defmodule PolicrMini.Cache do
  @moduledoc false

  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      # 群头像的缓存。
      %{
        id: :photo_cache,
        start: {Cachex, :start_link, [:photo, []]}
      },
      # 赞助令牌的缓存。
      %{
        id: :sponsorship_cache,
        start: {Cachex, :start_link, [:sponsorship, []]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end
end
