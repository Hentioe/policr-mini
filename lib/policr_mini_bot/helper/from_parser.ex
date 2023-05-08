defmodule PolicrMiniBot.Helper.FromParser do
  @moduledoc false

  alias Telegex.Model.Update

  @type chat_id :: binary | integer
  @type user_id :: binary | integer

  @spec parse(Update.t()) :: {chat_id, user_id} | :none
  def parse(update) do
    cond do
      update.message != nil ->
        %{chat: %{id: chat_id}, from: %{id: user_id}} = update.message

        {chat_id, user_id}

      update.edited_message != nil ->
        %{chat: %{id: chat_id}, from: %{id: user_id}} = update.edited_message

        {chat_id, user_id}

      update.callback_query != nil ->
        %{message: %{chat: %{id: chat_id}}, from: %{id: user_id}} = update.callback_query

        {chat_id, user_id}

      update.chat_member != nil ->
        %{from: %{id: user_id}, chat: %{id: chat_id}} = update.chat_member

        {chat_id, user_id}

      update.my_chat_member != nil ->
        %{from: %{id: user_id}, chat: %{id: chat_id}} = update.my_chat_member

        {chat_id, user_id}

      update.chat_join_request != nil ->
        %{from: %{id: user_id}, chat: %{id: chat_id}} = update.chat_join_request

        {chat_id, user_id}

      true ->
        :none
    end
  end

  @spec parse_chat_id(Update.t()) :: chat_id | :none
  def parse_chat_id(update) do
    case parse(update) do
      {chat_id, _user_id} ->
        chat_id

      :none ->
        :none
    end
  end
end
