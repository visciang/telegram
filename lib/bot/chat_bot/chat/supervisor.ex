defmodule Telegram.Bot.ChatBot.Chat.Supervisor do
  @moduledoc """
  ChatBot chat supervisor.
  """

  use Supervisor
  alias Telegram.Bot.ChatBot

  @spec start_link({module(), Telegram.Types.token()}) :: Supervisor.on_start()
  def start_link({chatbot_behaviour, max_bot_concurrency}) do
    Supervisor.start_link(__MODULE__, {chatbot_behaviour, max_bot_concurrency}, name: name(chatbot_behaviour))
  end

  @spec name(module()) :: atom()
  def name(chatbot_behaviour) do
    String.to_atom("#{__MODULE__}.#{chatbot_behaviour}")
  end

  @spec handle_update(module(), Telegram.Types.update(), Telegram.Types.token()) :: :ok
  def handle_update(chatbot_behaviour, update, token) do
    {:ok, chat_id} = Telegram.Bot.Utils.get_chat_id(update)

    get_chat_session_server(chatbot_behaviour, chat_id)
    |> case do
      {:ok, server} ->
        ChatBot.Chat.Session.Server.handle_update(server, update, token)

      {:error, :max_children} ->
        nil
    end

    :ok
  end

  @impl Supervisor
  def init({chatbot_behaviour, max_bot_concurrency}) do
    registry = {ChatBot.Chat.Registry, {chatbot_behaviour}}
    session_supervisor = {ChatBot.Chat.Session.Supervisor, {chatbot_behaviour, max_bot_concurrency}}

    children = [registry, session_supervisor]
    Supervisor.init(children, strategy: :one_for_all)
  end

  defp get_chat_session_server(chatbot_behaviour, chat_id) do
    ChatBot.Chat.Registry.lookup(chatbot_behaviour, chat_id)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :not_found} ->
        start_chat_session_server(chatbot_behaviour, chat_id)
    end
  end

  defp start_chat_session_server(chatbot_behaviour, chat_id) do
    ChatBot.Chat.Session.Supervisor.start_child(chatbot_behaviour, chat_id)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :max_children} = error ->
        error
    end
  end
end
