defmodule Telegram.ChatBot do
  @moduledoc ~S"""
  Telegram Chat Bot behaviour.

  The difference with `Telegram.Bot` behaviour is that the `Telegram.ChatBot` is "statefull" per chat_id,
  (see `chat_state` argument).

  Given that every "conversation" is associated with a long running process is up to you to consider
  a session timeout in your bot state machine design. If you don't you will saturate the max_bot_concurrency
  capacity and then your bot won't accept any new conversation.
  For this you can leverage the underlying gen_server timeout including the timeout in the return value
  of the `c:init/1` or `c:handle_update/3` callbacks or, if you need a more complex behaviour, via explicit
  timers in you bot.

  ## Example

  ```elixir
  defmodule HelloBot do
    use Telegram.ChatBot

    @session_ttl 60 * 1_000

    @impl Telegram.ChatBot
    def init(_chat) do
      count_state = 0
      {:ok, count_state, @session_ttl}
    end

    @impl Telegram.ChatBot
    def handle_update(%{"message" => %{"chat" => %{"id" => chat_id}}}, token, count_state) do
      count_state = count_state + 1

      Telegram.Api.request(token, "sendMessage",
        chat_id: chat_id,
        text: "Hey! You sent me #{count_state} messages"
      )

      {:ok, count_state, @session_ttl}
    end

    def handle_update(update, _token, count_state) do
      # ignore unknown updates

      {:ok, count_state, @session_ttl}
    end

    @impl Telegram.ChatBot
    def handle_info(msg, _token, _chat_id, count_state) do
      # direct message processing

      {:ok, count_state}
    end

    @impl Telegram.ChatBot
    def handle_timeout(token, chat_id, count_state) do
      Telegram.Api.request(token, "sendMessage",
        chat_id: chat_id,
        text: "See you!"
      )

      {:stop, count_state}
    end
  end
  ```
  """

  alias Telegram.Bot.ChatBot.Chat
  alias Telegram.Bot.ChatBot.Chat.Session
  alias Telegram.Bot.Utils
  alias Telegram.Types

  @type t :: module()

  @type chat :: map()
  @type chat_state :: any()

  @doc """
  Invoked once when the chat starts.
  Return the initial chat_state.
  """
  @callback init(chat :: chat()) ::
              {:ok, initial_state :: chat_state()}
              | {:ok, initial_state :: chat_state(), timeout :: timeout()}

  @doc """
  On resume callback.

  This callback is optional.
  A default implementation is injected with "use Telegram.ChatBot", it just returns the received state.
  """
  @callback handle_resume(chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}

  @doc """
  Receives the telegram update event and the "current" chat_state.
  Return the "updated" chat_state.
  """
  @callback handle_update(update :: Types.update(), token :: Types.token(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}
              | {:stop, next_chat_state :: chat_state()}
  @doc """
  On timeout callback.

  This callback is optional.
  A default implementation is injected with "use Telegram.ChatBot", it just stops the bot.
  """
  @callback handle_timeout(token :: Types.token(), chat_id :: String.t(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}
              | {:stop, next_chat_state :: chat_state()}

  @doc """
  On handle_info callback.

  Can be used to implement bots that act on scheduled events (using `Process.send/3` and `Process.send_after/4`) or to interact via direct message to a a specific chat session (using `lookup/2`).

  This callback is optional.
  If one is not implemented, the received message will be logged.
  """
  @callback handle_info(msg :: any(), token :: Types.token(), chat_id :: String.t(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}
              | {:stop, next_chat_state :: chat_state()}

  @optional_callbacks handle_resume: 1, handle_info: 4, handle_timeout: 3

  @doc false
  defmacro __using__(_use_opts) do
    quote location: :keep do
      @behaviour Telegram.ChatBot
      @behaviour Telegram.Bot.Dispatch

      require Logger

      @impl Telegram.ChatBot
      def handle_resume(chat_state) do
        {:ok, chat_state}
      end

      @impl Telegram.ChatBot
      def handle_info(msg, _token, _chat_id, chat_state) do
        Logger.error("#{inspect(__MODULE__)} received unexpected message in handle_info/4: #{inspect(msg)}~n")

        {:ok, chat_state}
      end

      @impl Telegram.ChatBot
      def handle_timeout(token, chat_id, chat_state) do
        {:stop, chat_state}
      end

      defoverridable handle_resume: 1, handle_info: 4, handle_timeout: 3

      @spec child_spec(Types.bot_opts()) :: Supervisor.child_spec()
      def child_spec(token: token, max_bot_concurrency: max_bot_concurrency) do
        id = Utils.name(__MODULE__, token)

        Supervisor.child_spec({Chat.Supervisor, {token, max_bot_concurrency}}, id: id)
      end

      @impl Telegram.Bot.Dispatch
      def dispatch_update(update, token) do
        Session.Server.handle_update(__MODULE__, token, update)

        :ok
      end

      @doc """
      Resume a ChatBot.
      A chat session for `chat_id` is restored at the previous `state`.

      It's caller responsability to pass the same token used to start this bot.
      """
      @spec resume(Types.token(), String.t(), term()) :: :ok | {:error, :already_started | :max_children}
      def resume(token, chat_id, state) do
        Session.Server.resume(__MODULE__, token, chat_id, state)
      end
    end
  end

  @doc """
  Lookup the pid of a specific chat session.

  It is up to the user to define and keep a mapping between
  the business logic specific session identifier and the telegram chat_id.
  """
  @spec lookup(Types.token(), String.t()) :: {:error, :not_found} | {:ok, pid}
  def lookup(token, chat_id) do
    Chat.Registry.lookup(token, chat_id)
  end
end
