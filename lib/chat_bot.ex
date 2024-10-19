defmodule Telegram.ChatBot do
  @moduledoc ~S"""
  Telegram Chat Bot behaviour.

  The `Telegram.ChatBot` module provides a stateful chatbot mechanism that manages bot instances
  on a per-chat basis (`chat_id`). Unlike the `Telegram.Bot` behavior, which is stateless,
  each conversation in `Telegram.ChatBot` is tied to a unique `chat_state`.

  The `c:get_chat/2` callback is responsible for routing each incoming update to the correct
  chat session by returning the chat's identifier. If the chat is not yet recognized,
  a new bot instance will automatically be created for that chat.

  Since each conversation is handled by a long-running process, it's crucial to manage session
  timeouts carefully. Without implementing timeouts, your bot may hit the `max_bot_concurrency` limit,
  preventing it from handling new conversations. To prevent this, you can utilize the underlying
  `:gen_server` timeout mechanism by specifying timeouts in the return values of the `c:init/1` or
  `c:handle_update/3` callbacks. Alternatively, for more complex scenarios, you can manage explicit
  timers in your bot's logic.

  ## Example

  ```elixir
  defmodule HelloBot do
    use Telegram.ChatBot

    # Session timeout set to 60 seconds
    @session_ttl 60 * 1_000

    @impl Telegram.ChatBot
    def init(_chat) do
      # Initialize state with a message counter set to 0
      count_state = 0
      {:ok, count_state, @session_ttl}
    end

    @impl Telegram.ChatBot
    def handle_update(%{"message" => %{"chat" => %{"id" => chat_id}}}, token, count_state) do
      # Increment the message count
      count_state = count_state + 1

      Telegram.Api.request(token, "sendMessage",
        chat_id: chat_id,
        text: "Hey! You sent me #{count_state} messages"
      )

      {:ok, count_state, @session_ttl}
    end

    def handle_update(update, _token, count_state) do
      # Ignore unknown updates and maintain the current state

      {:ok, count_state, @session_ttl}
    end

    @impl Telegram.ChatBot
    def handle_info(msg, _token, _chat_id, count_state) do
      # Handle direct erlang messages, if needed

      {:ok, count_state}
    end

    @impl Telegram.ChatBot
    def handle_timeout(token, chat_id, count_state) do
      # Send a "goodbye" message upon session timeout
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
  Invoked when a chat session is first initialized. Returns the initial `chat_state` for the session.

  ### Parameters:

  - `chat`: the `t:Telegram.ChatBot.Chat.t/0` struct returned by `c:get_chat/2`.

  ### Return values

  - `{:ok, initial_state}`: initializes the session with the provided `initial_state`.
  - `{:ok, initial_state, timeout}`: initializes the session with the provided `initial_state`, and sets a timeout for the session.

  The `timeout` can be used to schedule actions after a certain period of inactivity.
  """
  @callback init(chat :: Telegram.ChatBot.Chat.t()) ::
              {:ok, initial_state :: chat_state()}
              | {:ok, initial_state :: chat_state(), timeout :: timeout()}

  @doc """
  Invoked when a chat session is resumed.

  If implemented, this function allows custom logic when resuming a session, for example,
  updating the state or setting a new timeout.

  Note: you can manually resume a session by calling `MyChatBot.resume(token, chat_id, state)`.

  ### Return values

  - `{:ok, next_chat_state}`: resumes the session with the provided `next_chat_state`.
  - `{:ok, next_chat_state, timeout}`: resumes the session with the `next_chat_state` and sets a new `timeout`.

  The `timeout` can be used to schedule actions after a specific period of inactivity.
  """
  @callback handle_resume(chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}

  @doc """
  Handles incoming Telegram update events and processes them based on the current `chat_state`.

  ### Parameters:

  - `update`: the incoming Telegram [update](https://core.telegram.org/bots/api#update) event (e.g., a message, an inline query).
  - `token`: the bot's authentication token, used to make API requests.
  - `chat_state`: the current state of the chat session.

  ### Return values:

  - `{:ok, next_chat_state}`: updates the chat session with the new `next_chat_state`.
  - `{:ok, next_chat_state, timeout}`: updates the `next_chat_state` and sets a new `timeout` for the session.
  - `{:stop, next_chat_state}`: terminates the chat session and returns the final `next_chat_state`.

  The `timeout` option can be used to define how long the bot will wait for the next event before triggering a timeout.
  """
  @callback handle_update(update :: Types.update(), token :: Types.token(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}
              | {:stop, next_chat_state :: chat_state()}

  @doc """
  Callback invoked when a session times out.

  ### Parameters

  - `token`: the bot's authentication token, used for making API requests.
  - `chat_id`: the ID of the chat where the session timed out.
  - `chat_state`: the current state of the chat session at the time of the timeout.

  ### Return Values:

  - `{:ok, next_chat_state}`: keeps the session alive with an updated `next_chat_state`.
  - `{:ok, next_chat_state, timeout}`: updates the `next_chat_state` and sets a new `timeout`.
  - `{:stop, next_chat_state}`: terminates the session and finalizes the `chat_state`.

  This callback is **optional**.
  If not implemented, the bot will stops when a timeout occurs.
  """
  @callback handle_timeout(token :: Types.token(), chat_id :: String.t(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}
              | {:stop, next_chat_state :: chat_state()}

  @doc """
  Invoked to handle arbitrary erlang messages (e.g., scheduled events or direct messages).

  This callback can be used for:
  - Scheduled Events: handle messages triggered by Process.send/3 or Process.send_after/4.
  - Direct Interactions: respond to direct messages sent to a specific chat session retrieved via `lookup/2`.

  ### Parameters:

  - `msg`: the message received.
  - `token`: the bot's authentication token, used to make API requests.
  - `chat_id`: the ID of the chat session associated with the message.
  - `chat_state`: the current state of the chat session.

  ### Return values:

  - `{:ok, next_chat_state}`: updates the session with a new `next_chat_state`.
  - `{:ok, next_chat_state, timeout}`: updates the `next_chat_state` and sets a new `timeout`.
  - `{:stop, next_chat_state}`: terminates the session and returns the final `chat_state`.

  This callback is **optional**.
  If not implemented, any received message will be logged by default.
  """
  @callback handle_info(msg :: any(), token :: Types.token(), chat_id :: String.t(), chat_state :: chat_state()) ::
              {:ok, next_chat_state :: chat_state()}
              | {:ok, next_chat_state :: chat_state(), timeout :: timeout()}
              | {:stop, next_chat_state :: chat_state()}

  @doc """
  Allows a chatbot to customize how incoming updates are processed.

  ### Parameters:

  - `update_type`: is a string representing the type of update received. For example:
    - `message`: For new messages.
    - `edited_message`: For edited messages.
    - `inline_query`: For inline queries.
  - `update`: the update object received, containing the data associated with the `update_type`.
    The object structure depends on the type of update:
    - For `message` and `edited_message` updates, the object is of type [`Message`](https://core.telegram.org/bots/api#message),
      which contains fields such as text, sender, and chat.
    - For `inline_query` updates, the object is of type [`InlineQuery`](https://core.telegram.org/bots/api#inlinequery), containing fields like query and from.

  Refer to the official Telegram Bot API [documentation](https://core.telegram.org/bots/api#update)
  for a complete list of update types.

  ### Return values:

  - Returning `{:ok, %Telegram.ChatBot.Chat{id: id, metadata: [...]}}` will trigger
    the bot to spin up a new instance, which will manage the update as a full chat session.
    The instance will be uniquely identified by the return `id` and
    `c:init/1` will be called with the returned `t:Telegram.ChatBot.Chat.t/0` struct.
  - Returning `:ignore` will cause the update to be disregarded entirely.

  This callback is **optional**.
  If not implemented, the bot will dispatch updates of type [`Message`](https://core.telegram.org/bots/api#message).
  """
  @callback get_chat(update_type :: String.t(), update :: Types.update()) :: {:ok, Telegram.ChatBot.Chat.t()} | :ignore

  @optional_callbacks get_chat: 2, handle_resume: 1, handle_info: 4, handle_timeout: 3

  @doc false
  defmacro __using__(_use_opts) do
    quote location: :keep do
      @behaviour Telegram.ChatBot
      @behaviour Telegram.Bot.Dispatch

      require Logger

      @impl Telegram.ChatBot
      def get_chat(_, %{"chat" => %{"id" => chat_id} = chat}),
        do: {:ok, %Telegram.ChatBot.Chat{id: chat_id, metadata: [chat: chat]}}

      def get_chat(_, %{"message" => %{"chat" => %{"id" => chat_id} = chat}}),
        do: {:ok, %Telegram.ChatBot.Chat{id: chat_id, metadata: [chat: chat]}}

      def get_chat(_, _), do: :ignore

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

      defoverridable get_chat: 2, handle_resume: 1, handle_info: 4, handle_timeout: 3

      @spec child_spec(Types.bot_opts()) :: Supervisor.child_spec()
      def child_spec(bot_opts) do
        token = Keyword.fetch!(bot_opts, :token)
        max_bot_concurrency = Keyword.fetch!(bot_opts, :max_bot_concurrency)

        id = Utils.name(__MODULE__, token)

        Supervisor.child_spec({Chat.Supervisor, {token, max_bot_concurrency}}, id: id)
      end

      @impl Telegram.Bot.Dispatch
      def dispatch_update(update, token) do
        Session.Server.handle_update(__MODULE__, token, update)

        :ok
      end

      @doc """
      Resumes a `Telegram.ChatBot` sessions.

      Restores the chat session for the given `chat_id` using the previously saved `state`.

      Note: it is the caller's responsibility to provide the same `token` that was used
      when the bot was initially started.

      ### Return values:

      - `:ok`: The chat session was successfully resumed.
      - `{:error, :already_started}`: the chat session is already active and cannot be resumed.
      - `{:error, :max_children}`: the bot has reached its maximum concurrency limit and cannot accept new sessions.
      """
      @spec resume(Types.token(), String.t(), term()) :: :ok | {:error, :already_started | :max_children}
      def resume(token, chat_id, state) do
        Session.Server.resume(__MODULE__, token, chat_id, state)
      end
    end
  end

  @doc """
  Retrieves the process ID (`pid`) of a specific chat session.

  This function allows you to look up the active process managing a particular chat session

  Note: it is the user's responsibility to maintain and manage the mapping between
  the custom session identifier (specific to the business logic) and the Telegram `chat_id`.

  ### Return values:

  - `{:ok, pid}`: successfully found the pid of the chat session.
  - `{:error, :not_found}`: no active session was found for the provided `chat_id`.
  """
  @spec lookup(Types.token(), String.t()) :: {:error, :not_found} | {:ok, pid}
  def lookup(token, chat_id) do
    Chat.Registry.lookup(token, chat_id)
  end
end
