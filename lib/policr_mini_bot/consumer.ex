defmodule PolicrMiniBot.Consumer do
  use DynamicSupervisor

  alias PolicrMiniBot.{FilterManager, State}
  alias PolicrMini.{ChatBusiness, PermissionBusiness}

  def start_link(default \\ []) when is_list(default) do
    DynamicSupervisor.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def receive(%Telegex.Model.Update{} = update) do
    %{message: message, callback_query: callback_query} = update

    dispatch_message = fn ->
      message
      |> dispatch_commander
      |> dispatch_handler
    end

    dispatch_callback_query = fn -> callback_query |> dispatch_callbacker end

    if message, do: DynamicSupervisor.start_child(__MODULE__, {Task, dispatch_message})

    if callback_query,
      do: DynamicSupervisor.start_child(__MODULE__, {Task, dispatch_callback_query})
  end

  def dispatch_commander(message) do
    username = PolicrMiniBot.username()
    text = message.text

    applying = fn commander, state ->
      {_, state} =
        if commander.match?(text), do: commander.handle(message, state), else: {:ignored, state}

      state
    end

    %{chat: %{id: chat_id}, from: %{id: from_user_id, username: from_user_username}} = message

    takeovered =
      case ChatBusiness.get(chat_id) do
        {:ok, chat} -> chat.is_take_over || false
        _ -> false
      end

    # TODO: 待优化：根据 chat_id 是否大于 0 识别私聊以直接返回 false
    from_admin = if PermissionBusiness.find(chat_id, from_user_id) != nil, do: true, else: false
    from_self = from_user_username != nil && from_user_username == username

    init_state = %State{
      takeovered: takeovered,
      from_self: from_self,
      from_admin: from_admin,
      deleted: false,
      done: false
    }

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

  def dispatch_callbacker(callback_query) do
    applying = fn callbacker ->
      if callbacker.match?(callback_query.data),
        do: callbacker.handle(callback_query),
        else: :ignored
    end

    callbackers = FilterManager.callbackers()
    callbackers |> Enum.each(applying)
  end
end
