defmodule PolicrMiniBot.JoinReuquestHosting do
  @moduledoc false

  use Agent
  use TypedStruct

  typedstruct module: Request do
    @type status :: :pending | :approved

    field :date, :integer
    field :status, status
  end

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec get(integer, integer) :: Request.t() | nil
  def get(chat_id, user_id) do
    Agent.get(__MODULE__, &Map.get(&1, keygen(chat_id, user_id)))
  end

  @spec put(integer, integer, integer, Request.status()) :: :ok
  def put(chat_id, user_id, date, status) do
    update_fun = fn state ->
      Map.put(state, keygen(chat_id, user_id), %Request{
        date: date,
        status: status
      })
    end

    Agent.update(__MODULE__, update_fun)
  end

  @spec update_status(integer, integer, Request.status()) :: :ok
  def update_status(chat_id, user_id, status) do
    update_fun = fn state ->
      Map.update(state, keygen(chat_id, user_id), %Request{status: status}, fn r ->
        %{r | status: status}
      end)
    end

    Agent.update(__MODULE__, update_fun)
  end

  def delete(chat_id, user_id) do
    Agent.update(__MODULE__, fn state -> Map.delete(state, keygen(chat_id, user_id)) end)
  end

  defp keygen(chat_id, user_id) do
    "#{chat_id}:#{user_id}"
  end
end
