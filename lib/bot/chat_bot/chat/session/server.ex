defmodule Telegram.Bot.ChatBot.Chat.Session.Server do
  @moduledoc """
  ChatBot chat session server.
  """

  use GenServer, restart: :transient
  alias Telegram.Bot.{ChatBot.Chat, Utils}

  @spec start_link({module(), String.t()}) :: GenServer.on_start()
  def start_link({chatbot_behaviour, chat_id}) do
    GenServer.start_link(
      __MODULE__,
      {chatbot_behaviour},
      name: Chat.Registry.via(chatbot_behaviour, chat_id)
    )
  end

  @spec handle_update(module(), Telegram.Types.update(), Telegram.Types.token()) :: :ok
  def handle_update(chatbot_behaviour, update, token) do
    {:ok, chat_id} = Utils.get_chat_id(update)

    get_chat_session_server(chatbot_behaviour, chat_id)
    |> case do
      {:ok, server} ->
        GenServer.cast(server, {:handle_update, update, token})

      {:error, :max_children} ->
        nil
    end
  end

  @impl GenServer
  def init({chatbot_behaviour}) do
    {:ok, bot_state} = chatbot_behaviour.init()
    {:ok, {chatbot_behaviour, bot_state}}
  end

  @impl GenServer
  def handle_cast({:handle_update, update, token}, {chatbot_behaviour, bot_state}) do
    chatbot_behaviour.handle_update(update, token, bot_state)
    |> case do
      {:ok, bot_state} ->
        {:noreply, {chatbot_behaviour, bot_state}}

      {:stop, _reason, _bot_state} = stop ->
        {:ok, chat_id} = Utils.get_chat_id(update)
        Chat.Registry.unregister(chatbot_behaviour, chat_id)
        stop
    end
  end

  defp get_chat_session_server(chatbot_behaviour, chat_id) do
    Chat.Registry.lookup(chatbot_behaviour, chat_id)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :not_found} ->
        start_chat_session_server(chatbot_behaviour, chat_id)
    end
  end

  defp start_chat_session_server(chatbot_behaviour, chat_id) do
    Chat.Session.Supervisor.start_child(chatbot_behaviour, chat_id)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :max_children} = error ->
        error
    end
  end
end
