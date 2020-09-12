defmodule Telegram.Bot.ChatBot.Chat.Registry do
  @moduledoc """
  ChatBot chat registry.
  """

  @spec child_spec({module()}) :: Supervisor.child_spec()
  def child_spec({chatbot_behaviour}) do
    Registry.child_spec(keys: :unique, name: Telegram.Bot.Utils.name(__MODULE__, chatbot_behaviour))
  end

  @spec lookup(module(), String.t()) :: {:error, :not_found} | {:ok, pid}
  def lookup(chatbot_behaviour, chat_id) do
    Registry.lookup(Telegram.Bot.Utils.name(__MODULE__, chatbot_behaviour), chat_id)
    |> case do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        {:error, :not_found}
    end
  end

  @spec via(module(), String.t()) :: {:via, Registry, {Registry.registry(), any()}}
  def via(bot_behaviour, chat_id) do
    {:via, Registry, {Telegram.Bot.Utils.name(__MODULE__, bot_behaviour), chat_id}}
  end
end
