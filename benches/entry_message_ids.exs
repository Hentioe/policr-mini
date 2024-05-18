import PolicrMiniBot.Entry.Helper

:ok = init_table()

defmodule Testing do
  def save_entry_message_id do
    :ok = save_entry_message_id(:erlang.unique_integer(), :erlang.unique_integer())
  end

  def load_entry_message_id do
    _ = load_entry_message_id(:erlang.unique_integer())
  end

  def clear_entry_message_id do
    :ok = clear_entry_message_id(:erlang.unique_integer())
  end
end

Benchee.run(%{
  "save_entry_message_id" => fn -> Testing.save_entry_message_id() end,
  "load_entry_message_id" => fn -> Testing.load_entry_message_id() end,
  "clear_entry_message_id" => fn -> Testing.clear_entry_message_id() end
})
