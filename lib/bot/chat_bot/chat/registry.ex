defmodule Telegram.Bot.ChatBot.Chat.Registry do
  @moduledoc """
  ChatBot chat registry.
  """

  @spec child_spec({module()}) :: Supervisor.child_spec()
  def child_spec({chatbot_behaviour}) do
    Registry.child_spec(keys: :unique, name: name(chatbot_behaviour))
  end

  @spec name(module()) :: atom()
  def name(chatbot_behaviour) do
    String.to_atom("#{__MODULE__}.#{chatbot_behaviour}")
  end

  @spec lookup(module(), String.t()) :: {:error, :not_found} | {:ok, pid}
  def lookup(chatbot_behaviour, chat_id) do
    Registry.lookup(name(chatbot_behaviour), chat_id)
    |> case do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        {:error, :not_found}
    end
  end
end
