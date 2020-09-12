defmodule Telegram.Bot.ChatBot.Chat.Session.Server do
  @moduledoc """
  ChatBot chat session server.
  """

  use GenServer, restart: :transient
  alias Telegram.Bot.ChatBot

  @spec start_link({module(), String.t()}) :: GenServer.on_start()
  def start_link({chatbot_behaviour, chat_id}) do
    GenServer.start_link(
      __MODULE__,
      {chatbot_behaviour},
      name: {:via, Registry, {ChatBot.Chat.Registry.name(chatbot_behaviour), chat_id}}
    )
  end

  @spec handle_update(GenServer.server(), Telegram.Types.update(), Telegram.Types.token()) :: :ok
  def handle_update(server, update, token) do
    GenServer.cast(server, {:handle_update, update, token})
  end

  @impl GenServer
  def init({chatbot_behaviour}) do
    {:ok, bot_state} = chatbot_behaviour.init()
    {:ok, {chatbot_behaviour, bot_state}}
  end

  @impl GenServer
  def handle_cast({:handle_update, update, token}, {chatbot_behaviour, bot_state}) do
    {:ok, bot_state} = chatbot_behaviour.handle_update(update, token, bot_state)
    {:noreply, {chatbot_behaviour, bot_state}}
  end
end
