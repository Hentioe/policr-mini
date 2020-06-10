defmodule PolicrMini.Bot.Consumer do
  use DynamicSupervisor

  alias PolicrMini.Bot.{FilterManager, State}

  def start_link(default \\ []) when is_list(default) do
    DynamicSupervisor.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def receive(%Nadia.Model.Update{} = update, username) do
    message = update.message

    dispatch_msg = fn ->
      message
      |> dispatch_commander(username)
      |> dispatch_handler
    end

    if message, do: DynamicSupervisor.start_child(__MODULE__, {Task, dispatch_msg})
  end

  def dispatch_commander(message, username) do
    text = message.text

    applying = fn commander, state ->
      command_name = commander.command()
      match = text == command_name || text == "#{command_name}@#{username}"
      {_, state} = if match, do: commander.handle(message, state), else: {:ignored, state}

      state
    end

    init_state = %State{}

    state =
      if text do
        commanders = FilterManager.commanders()
        commanders |> Enum.reduce(init_state, applying)
      else
        init_state
      end

    {message, state}
  end

  def dispatch_handler({message, state}) do
    applying = fn handler, state ->
      {is_match, state} = handler.match?(message, state)
      {_, state} = if is_match, do: handler.handle(message, state), else: {:ignored, state}

      state
    end

    handlers = FilterManager.handlers()
    handlers |> Enum.reduce(state, applying)

    message
  end
end
