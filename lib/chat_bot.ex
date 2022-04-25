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
        def handle_timeout(token, chat_id, count_state) do
          Telegram.Api.request(token, "sendMessage",
            chat_id: chat_id,
            text: "See you!"
          )

          super(token, chat_id, count_state)
        end
      end
  """

  alias Telegram.Bot.ChatBot.Chat
  alias Telegram.Bot.ChatBot.Chat.Session
  alias Telegram.Types

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
  Receives the telegram update event and the "current" chat_state.
  Return the "updated" chat_state.
  """
  @callback handle_update(update :: Types.update(), token :: Types.token(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}
              | {:stop, next_chat_state :: chat_state()}
  @doc """
  On timeout callback.
  A default implementation is injected with "use Telegram.ChatBot", it just stops the bot.
  """
  @callback handle_timeout(token :: Types.token(), chat_id :: String.t(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}
              | {:stop, next_chat_state :: chat_state()}

  @doc false
  defmacro __using__(_use_opts) do
    quote location: :keep do
      @behaviour Telegram.ChatBot

      @impl Telegram.ChatBot
      def handle_timeout(token, chat_id, chat_state) do
        {:stop, chat_state}
      end

      defoverridable handle_timeout: 3

      @spec child_spec(Types.bot_opts()) :: Supervisor.child_spec()
      def child_spec(token: token, max_bot_concurrency: max_bot_concurrency) do
        Supervisor.child_spec({Chat.Supervisor, {token, max_bot_concurrency}}, [])
      end

      @spec dispatch_update(Types.update(), Types.token()) :: :ok
      def dispatch_update(update, token) do
        Session.Server.handle_update(__MODULE__, token, update)

        :ok
      end
    end
  end
end
