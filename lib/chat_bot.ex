defmodule Telegram.ChatBot do
  @moduledoc ~S"""
  Telegram Chat Bot behaviour.

  The difference with `Telegram.Bot` behaviour is that the `Telegram.ChatBot` is "statefull" per chat_id,
  (see `chat_state` argument)

  ## Example

      defmodule HelloBot do
        use Telegram.ChatBot

        @impl Telegram.ChatBot
        def init(_chat) do
          count_state = 0
          {:ok, count_state}
        end

        @impl Telegram.ChatBot
        def handle_update(%{"message" => %{"chat" => %{"id" => chat_id}}}, token, count_state) do
          count_state = count_state + 1

          Telegram.Api.request(token, "sendMessage",
            chat_id: chat_id,
            text: "Hey! You sent me #{count_state} messages"
          )

          {:ok, count_state}
        end

        def handle_update(update, _token, count_state) do
          # ignore unknown updates

          {:ok, count_state}
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
  @callback init(chat :: chat()) :: {:ok, chat_state()}

  @doc """
  Receives the telegram update event and the "current" chat_state.
  Return the "updated" chat_state.
  """
  @callback handle_update(update :: Types.update(), token :: Types.token(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()} | {:stop, next_chat_state :: chat_state()}

  @doc false
  defmacro __using__(_use_opts) do
    quote location: :keep do
      @behaviour Telegram.ChatBot

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
