defmodule Telegram.Bot.ChatBot.Chat.Supervisor do
  @moduledoc """
  ChatBot chat supervisor.
  """

  use Supervisor
  alias Telegram.Bot.ChatBot

  @spec start_link({module(), Telegram.Client.token()}) :: Supervisor.on_start()
  def start_link({bot_module, max_bot_concurrency}) do
    Supervisor.start_link(__MODULE__, {bot_module, max_bot_concurrency}, name: name(bot_module))
  end

  @spec name(module()) :: atom()
  def name(bot_module) do
    String.to_atom("#{__MODULE__}.#{bot_module}")
  end

  @spec handle_update(module(), map(), Telegram.Client.token()) :: :ok
  def handle_update(bot_module, update, token) do
    {:ok, chat_id} = Telegram.Bot.Utils.get_chat_id(update)

    get_chat_session_server(bot_module, chat_id)
    |> case do
      {:ok, server} ->
        ChatBot.Chat.Session.Server.handle_update(server, update, token)

      {:error, :max_children} ->
        nil
    end

    :ok
  end

  @impl Supervisor
  def init({bot_module, max_bot_concurrency}) do
    registry = {ChatBot.Chat.Registry, {bot_module}}
    session_supervisor = {ChatBot.Chat.Session.Supervisor, {bot_module, max_bot_concurrency}}

    children = [registry, session_supervisor]
    Supervisor.init(children, strategy: :one_for_all)
  end

  defp get_chat_session_server(bot_module, chat_id) do
    ChatBot.Chat.Registry.lookup(bot_module, chat_id)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :not_found} ->
        start_chat_session_server(bot_module, chat_id)
    end
  end

  defp start_chat_session_server(bot_module, chat_id) do
    ChatBot.Chat.Session.Supervisor.start_child(bot_module, chat_id)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :max_children} = error ->
        error
    end
  end
end
