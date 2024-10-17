defmodule Telegram.Bot.ChatBot.Chat.Session.Server do
  @moduledoc false

  use GenServer, restart: :transient
  require Logger
  alias Telegram.Bot.{ChatBot.Chat, Utils}
  alias Telegram.{ChatBot, Types}

  defmodule State do
    @moduledoc false

    @enforce_keys [:chatbot_behaviour, :token, :chat_id, :bot_state]
    defstruct @enforce_keys
  end

  @spec start_link({ChatBot.t(), Types.token(), ChatBot.chat()}) :: GenServer.on_start()
  def start_link({chatbot_behaviour, token, %{"id" => chat_id} = chat}) do
    GenServer.start_link(
      __MODULE__,
      {chatbot_behaviour, token, chat},
      name: Chat.Registry.via(token, chat_id)
    )
  end

  @spec resume(ChatBot.t(), Types.token(), String.t(), term()) :: :ok | {:error, :already_started | :max_children}
  def resume(chatbot_behaviour, token, chat_id, state) do
    chat = %{"resume" => :resume, "id" => chat_id, "state" => state}

    with {:lookup, {:error, :not_found}} <- {:lookup, Chat.Registry.lookup(token, chat_id)},
         {:start, {:ok, _server}} <- {:start, start_chat_session_server(chatbot_behaviour, token, chat)} do
      :ok
    else
      # coveralls-ignore-start
      {:lookup, {:ok, _server}} ->
        {:error, :already_started}

      {:start, {:error, :max_children} = error} ->
        error
        # coveralls-ignore-stop
    end
  end

  @spec handle_update(ChatBot.t(), Types.token(), Types.update()) :: :ok
  def handle_update(chatbot_behaviour, token, update) do
    with {:get_chat, {chat_type, chat}} <- {:get_chat, get_chat(chatbot_behaviour, update)},
         {:get_chat_session_server, {:ok, server}} <-
           {:get_chat_session_server, get_chat_session_server(chatbot_behaviour, token, chat)} do
      GenServer.cast(server, {:handle_update, chat_type, update})
    else
      {:get_chat, nil} ->
        Logger.info("Dropped update without chat #{inspect(update)}", bot: chatbot_behaviour, token: token)

      {:get_chat_session_server, {:error, :max_children}} ->
        Logger.info("Reached max children, update dropped", bot: chatbot_behaviour, token: token)
    end

    :ok
  end

  defp get_chat(chatbot_behaviour, update) do
    if function_exported?(chatbot_behaviour, :get_chat, 2) do
      update_type =
        update
        |> Map.drop(["update_id"])
        |> Map.keys()
        |> List.first()

      chatbot_behaviour.get_chat(update_type, Map.get(update, update_type))
    else
      Utils.get_chat(update)
    end
  end

  @impl GenServer
  def init({chatbot_behaviour, token, %{"resume" => :resume, "id" => chat_id, "state" => bot_state}}) do
    Logger.metadata(bot: chatbot_behaviour, chat_id: chat_id)

    state = %State{token: token, chatbot_behaviour: chatbot_behaviour, chat_id: chat_id, bot_state: bot_state}

    case chatbot_behaviour.handle_resume(bot_state) do
      {:ok, bot_state} ->
        {:ok, put_in(state.bot_state, bot_state)}

      {:ok, bot_state, timeout} ->
        # coveralls-ignore-start
        {:ok, put_in(state.bot_state, bot_state), timeout}
        # coveralls-ignore-stop
    end
  end

  def init({chatbot_behaviour, token, %{"id" => chat_id} = chat}) do
    Logger.metadata(bot: chatbot_behaviour, chat_id: chat_id)

    state = %State{token: token, chatbot_behaviour: chatbot_behaviour, chat_id: chat_id, bot_state: nil}

    chatbot_behaviour.init(chat)
    |> case do
      {:ok, bot_state} ->
        {:ok, put_in(state.bot_state, bot_state)}

      {:ok, bot_state, timeout} ->
        {:ok, put_in(state.bot_state, bot_state), timeout}
    end
  end

  @impl GenServer
  def handle_cast({:handle_update, chat_type, update}, %State{} = state) do
    res = state.chatbot_behaviour.handle_update(update, state.token, state.bot_state)

    if chat_type == :transient do
      handle_callback_result({:stop, elem(res, 1)}, state)
    else
      handle_callback_result(res, state)
    end
  end

  @impl GenServer
  def handle_info(:timeout, %State{} = state) do
    Logger.debug("Reached timeout")

    res = state.chatbot_behaviour.handle_timeout(state.token, state.chat_id, state.bot_state)
    handle_callback_result(res, state)
  end

  @impl GenServer
  def handle_info(msg, %State{} = state) do
    res = state.chatbot_behaviour.handle_info(msg, state.token, state.chat_id, state.bot_state)
    handle_callback_result(res, state)
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
    child_spec = {__MODULE__, {chatbot_behaviour, token, chat}}

    Chat.Session.Supervisor.start_child(child_spec, token)
    |> case do
      {:ok, _server} = ok ->
        ok

      {:error, :max_children} = error ->
        error
    end
  end

  defp handle_callback_result(result, %State{} = state) do
    case result do
      {:ok, bot_state} ->
        {:noreply, put_in(state.bot_state, bot_state)}

      {:ok, bot_state, timeout} ->
        {:noreply, put_in(state.bot_state, bot_state), timeout}

      {:stop, bot_state} ->
        Chat.Registry.unregister(state.token, state.chat_id)
        {:stop, :normal, put_in(state.bot_state, bot_state)}
    end
  end
end
