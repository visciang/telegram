defmodule Telegram.Bot.ChatBot.Chat.Registry do
  @moduledoc false

  alias Telegram.Bot.Utils
  alias Telegram.Types

  @spec child_spec({Types.token()}) :: Supervisor.child_spec()
  def child_spec({token}) do
    Registry.child_spec(keys: :unique, name: Utils.name(__MODULE__, token))
  end

  @spec lookup(Types.token(), String.t()) :: {:error, :not_found} | {:ok, pid}
  def lookup(token, chat_id) do
    Registry.lookup(Utils.name(__MODULE__, token), chat_id)
    |> case do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        {:error, :not_found}
    end
  end

  @spec unregister(Types.token(), String.t()) :: :ok
  def unregister(token, chat_id) do
    Registry.unregister(Utils.name(__MODULE__, token), chat_id)
  end

  @spec via(Types.token(), String.t()) :: {:via, Registry, {Registry.registry(), any()}}
  def via(token, chat_id) do
    {:via, Registry, {Utils.name(__MODULE__, token), chat_id}}
  end
end
