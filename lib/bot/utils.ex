defmodule Telegram.Bot.Utils do
  @moduledoc """
  Bot utilities
  """

  alias Telegram.Types

  @doc """
  Process name atom maker.
  Composed by Supervisor/GenServer/_ module name + bot behaviour module name
  """
  @spec name(module(), Types.token()) :: atom()
  def name(module, token) do
    String.to_atom("#{module}.#{token}")
  end

  @doc """
  Get the "from.user" field in an Update object, if present
  """
  @spec get_from_username(Types.update()) :: {:ok, String.t()} | nil
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
  @spec get_sent_date(Types.update()) :: {:ok, DateTime.t()} | nil
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
  Get the "chat" field in an Update object, if present
  """
  @spec get_chat(Types.update()) :: {:ok, map()} | nil
  def get_chat(update) do
    Enum.find_value(update, fn
      {_update_type, %{"chat" => %{"id" => _} = chat}} ->
        {:ok, chat}

      _ ->
        nil
    end)
  end
end
