defmodule Telegram.Bot.ChatBot.Chat.Registry do
  @moduledoc """
  ChatBot chat registry.
  """

  @spec child_spec({module()}) :: Supervisor.child_spec()
  def child_spec({bot_module}) do
    Registry.child_spec(keys: :unique, name: name(bot_module))
  end

  @spec name(module()) :: atom()
  def name(bot_module) do
    String.to_atom("#{__MODULE__}.#{bot_module}")
  end

  @spec lookup(module(), String.t()) :: {:error, :not_found} | {:ok, pid}
  def lookup(bot_module, chat_id) do
    Registry.lookup(name(bot_module), chat_id)
    |> case do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        {:error, :not_found}
    end
  end
end
