defmodule Telegram.Bot.ChatBot.Chat.Session.Server do
  @moduledoc """
  ChatBot chat session server.
  """

  use GenServer, restart: :transient
  require Logger
  alias Telegram.Bot.{ChatBot.Chat, Utils}
  alias Telegram.ChatBot

  @spec start_link({module(), ChatBot.chat()}) :: GenServer.on_start()
  def start_link({chatbot_behaviour, %{"id" => chat_id} = chat}) do
    GenServer.start_link(
      __MODULE__,
      {chatbot_behaviour, chat},
      name: Chat.Registry.via(chatbot_behaviour, chat_id)
    )
  end

  @spec handle_update(module(), Telegram.Types.update(), Telegram.Types.token()) :: any()
  def handle_update(chatbot_behaviour, update, token) do
    with {:get_chat, {:ok, chat}} <- {:get_chat, Utils.get_chat(update)},
         {:get_chat_session_server, {:ok, server}} <-
           {:get_chat_session_server, get_chat_session_server(chatbot_behaviour, chat)} do
      GenServer.cast(server, {:handle_update, update, token})
    else
      {:get_chat, nil} ->
        Logger.info("Dropped update without chat #{inspect(update)}")

      {:get_chat_session_server, {:error, :max_children}} ->
        Logger.info("Reached #{__MODULE__} max children, update dropped")
    end
  end

  @impl GenServer
  def init({chatbot_behaviour, chat}) do
    {:ok, bot_state} = chatbot_behaviour.init(chat)
    {:ok, {chatbot_behaviour, bot_state}}
  end

  @impl GenServer
  def handle_cast({:handle_update, update, token}, {chatbot_behaviour, bot_state}) do
    chatbot_behaviour.handle_update(update, token, bot_state)
    |> case do
      {:ok, bot_state} ->
        {:noreply, {chatbot_behaviour, bot_state}}

      {:stop, bot_state} ->
        {:ok, %{"id" => chat_id}} = Utils.get_chat(update)
        Chat.Registry.unregister(chatbot_behaviour, chat_id)
        {:stop, :normal, bot_state}
    end
  end

  defp get_chat_session_server(chatbot_behaviour, %{"id" => chat_id} = chat) do
    Chat.Registry.lookup(chatbot_behaviour, chat_id)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :not_found} ->
        start_chat_session_server(chatbot_behaviour, chat)
    end
  end

  defp start_chat_session_server(chatbot_behaviour, chat) do
    Chat.Session.Supervisor.start_child(chatbot_behaviour, chat)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :max_children} = error ->
        error
    end
  end
end
