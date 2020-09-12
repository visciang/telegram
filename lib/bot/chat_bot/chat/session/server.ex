defmodule Telegram.Bot.ChatBot.Chat.Session.Server do
  @moduledoc """
  ChatBot chat session server.
  """

  use GenServer, restart: :transient
  alias Telegram.Bot.ChatBot

  @spec start_link({module(), String.t()}) :: GenServer.on_start()
  def start_link({bot_module, chat_id}) do
    GenServer.start_link(
      __MODULE__,
      {bot_module},
      name: {:via, Registry, {ChatBot.Chat.Registry.name(bot_module), chat_id}}
    )
  end

  @spec handle_update(GenServer.server(), Telegram.Types.update(), Telegram.Types.token()) :: :ok
  def handle_update(server, update, token) do
    GenServer.cast(server, {:handle_update, update, token})
  end

  @impl GenServer
  def init({bot_module}) do
    {:ok, bot_state} = bot_module.init()
    {:ok, {bot_module, bot_state}}
  end

  @impl GenServer
  def handle_cast({:handle_update, update, token}, {bot_module, bot_state}) do
    {:ok, bot_state} = bot_module.handle_update(update, token, bot_state)
    {:noreply, {bot_module, bot_state}}
  end
end
