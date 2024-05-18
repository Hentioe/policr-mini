defmodule PolicrMiniBot.Entry.Helper do
  @moduledoc false

  alias :dets, as: Dets

  @table :entry_message_ids
  @data_dir "nonmigrated_data"

  defp data_path do
    if !File.exists?(@data_dir) do
      File.mkdir_p!(@data_dir)
    end

    @data_dir |> Path.join("entry_message_ids") |> String.to_charlist()
  end

  def init_table do
    {:ok, _} = Dets.open_file(@table, type: :set, auto_save: 5, file: data_path())

    :ok
  end

  def save_entry_message_id(chat_id, message_id) do
    Dets.insert(@table, {chat_id, message_id})
  end

  def load_entry_message_id(chat_id) do
    case Dets.lookup(@table, chat_id) do
      [] -> nil
      [{_, value}] -> value
    end
  end

  def clear_entry_message_id(chat_id) do
    Dets.delete(@table, chat_id)
  end
end
