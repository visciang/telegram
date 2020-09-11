defmodule Telegram.Bot.Utils do
  @moduledoc """
  Bot utilities
  """

  @doc """
  Get the "from.user" field in an Update object, if present
  """
  @spec get_from_username(map()) :: {:ok, String.t()} | nil
  def get_from_username(update) do
    Enum.find_value(update, fn
      {_update_type, %{"from" => %{"username" => username}}} ->
        {:ok, username}

      _ ->
        nil
    end)
  end

  @doc """
  Get the sent "date" field in an Update object, if present
  """
  @spec get_sent_date(map()) :: {:ok, DateTime.t()} | nil
  def get_sent_date(update) do
    Enum.find_value(update, fn
      {_update_type, %{"date" => date}} ->
        # sent date is UTC
        {:ok, DateTime.from_unix!(date, :second)}

      _ ->
        nil
    end)
  end

  @doc """
  Get the "chat_id" field in an Update object, if present
  """
  @spec get_chat_id(map()) :: {:ok, String.t()} | nil
  def get_chat_id(update) do
    Enum.find_value(update, fn
      {_update_type, %{"chat" => %{"id" => chat_id}}} ->
        {:ok, chat_id}

      _ ->
        nil
    end)
  end
end
