defmodule Telegram.Bot.ChatBot.Chat.Session.Server do
  @moduledoc """
  ChatBot chat session server.
  """

  use GenServer, restart: :transient
  require Logger
  alias Telegram.Bot.{ChatBot.Chat, Utils}
  alias Telegram.{ChatBot, Types}

  @spec start_link({module(), Types.token(), ChatBot.chat()}) :: GenServer.on_start()
  def start_link({chatbot_behaviour, token, %{"id" => chat_id} = chat}) do
    GenServer.start_link(
      __MODULE__,
      {chatbot_behaviour, token, chat},
      name: Chat.Registry.via(token, chat_id)
    )
  end

  @spec handle_update(module(), Types.token(), Types.update()) :: any()
  def handle_update(chatbot_behaviour, token, update) do
    with {:get_chat, {:ok, chat}} <- {:get_chat, Utils.get_chat(update)},
         {:get_chat_session_server, {:ok, server}} <-
           {:get_chat_session_server, get_chat_session_server(chatbot_behaviour, token, chat)} do
      GenServer.cast(server, {:handle_update, update, token})
    else
      {:get_chat, nil} ->
        Logger.info("Dropped update without chat #{inspect(update)}", bot: chatbot_behaviour, token: token)

      {:get_chat_session_server, {:error, :max_children}} ->
        Logger.info("Reached max children, update dropped", bot: chatbot_behaviour, token: token)
    end
  end

  @impl GenServer
  def init({chatbot_behaviour, token, chat}) do
    Logger.metadata(bot: chatbot_behaviour, token: token)

    chatbot_behaviour.init(chat)
    |> case do
      {:ok, bot_state} ->
        {:ok, {chatbot_behaviour, bot_state}}

      {:ok, bot_state, timeout} ->
        {:ok, {chatbot_behaviour, bot_state}, timeout}
    end
  end

  @impl GenServer
  def handle_cast({:handle_update, update, token}, {chatbot_behaviour, bot_state}) do
    chatbot_behaviour.handle_update(update, token, bot_state)
    |> case do
      {:ok, bot_state} ->
        {:noreply, {chatbot_behaviour, bot_state}}

      {:ok, bot_state, timeout} ->
        {:noreply, {chatbot_behaviour, bot_state}, timeout}

      {:stop, bot_state} ->
        {:ok, %{"id" => chat_id}} = Utils.get_chat(update)
        Chat.Registry.unregister(token, chat_id)

        {:stop, :normal, {chatbot_behaviour, bot_state}}
    end
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    Logger.debug("Stop bot, reached timeout")

    {:stop, :normal, state}
  end

  defp get_chat_session_server(chatbot_behaviour, token, %{"id" => chat_id} = chat) do
    Chat.Registry.lookup(token, chat_id)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :not_found} ->
        start_chat_session_server(chatbot_behaviour, token, chat)
    end
  end

  defp start_chat_session_server(chatbot_behaviour, token, chat) do
    Chat.Session.Supervisor.start_child(chatbot_behaviour, token, chat)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :max_children} = error ->
        error
    end
  end
end
