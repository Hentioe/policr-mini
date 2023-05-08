defmodule PolicrMiniBot.Consumer do
  @moduledoc """
  消息更新的消费实现。
  """

  use DynamicSupervisor

  alias PolicrMiniBot.State

  require Logger

  def start_link(default \\ []) when is_list(default) do
    DynamicSupervisor.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def receive(%Telegex.Model.Update{} = update) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Task, fn -> task(update) end}
    )
  end

  defp task(update) do
    try do
      Telegex.Plug.Pipeline.call(update, %State{})
    rescue
      e ->
        import PolicrMiniBot.Helper.FromParser

        chat_id = parse_chat_id(update)

        Logger.error("Uncaught Error: #{inspect(e)}", chat_id: chat_id)

        reraise e, __STACKTRACE__
    end
  end
end
