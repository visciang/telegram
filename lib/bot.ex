defmodule Telegram.Bot do
  @moduledoc ~S"""
  A simple BOT behaviour and DSL.

  ## Example

  ```elixir
  defmodule Simple.Bot do
    use Telegram.Bot,
      token: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11",
      username: "simple_bot",
      auth: ["user1", "user2"]

    command ["ciao", "hello"], args do
      # handle the commands: "/ciao" and "/hello"

      # reply with a text message
      request "sendMessage",
        chat_id: update["chat"]["id"],
        text: "ciao! #{inspect args}"
    end

    command unknown do
      request "sendMessage", chat_id: update["chat"]["id"],
        text: "Unknow command `#{unknown}`"
    end

    message do
      request "sendMessage", chat_id: update["chat"]["id"],
        text: "Hey! You sent me a message: #{inspect update}"
    end

    edited_message do
      # handler code
    end

    channel_post do
      # handler code
    end

    edited_channel_post do
      # handler code
    end

    inline_query _query do
      # handler code
    end

    chosen_inline_result _query do
      # handler code
    end

    callback_query do
      # handler code
    end

    shipping_query do
      # handler code
    end

    pre_checkout_query do
      # handler code
    end

    any do
      # handler code
    end
  end
  ```

  See `Telegram.Bot.Dsl` documentation for all available macros.

  ## Options

  ```elixir
  use Telegram.Bot,
    token: "your bot auth token",   # required
    username: "your bot username",  # required
    auth: ["user1", "user2"],       # optional, list of authorized users
                                    # or authorizing function (String.t -> boolean)
    restart: policy                 # optional, default :permanent
  ```

  ## Execution model

  The bot defined using the `Telegram.Bot` behaviour is based on `Task`
  and will run in a single erlang process, processing updates sequentially.

  You can add the bot to you application supervisor tree, for example:

  ```elixir
    children = [Simple.Bot, ...]
    opts = [strategy: :one_for_one, name: MyApplication.Supervisor]
    Supervisor.start_link(children, opts)
  ```

  or directly start and link the bot with:

  ```elixir
  {:ok, pid} = Simple.Bot.start_link()
  ```
  """
  require Logger

  defmodule Context do
    @moduledoc false
    defstruct [:module, :token, :offset, :type]
    @type t :: %__MODULE__{module: module, token: String.t, offset: integer}
  end

  defmodule Halt do
    @moduledoc false
    defexception [:message]
  end

  @callback init() :: any
  @callback handle_auth(username :: String.t) :: boolean
  @callback handle_update(token :: String.t, update :: map) :: any

  @poll_timeout 30
  @retry_quiet_period 5

  defmacro __using__(opts) do
    token = Keyword.fetch!(opts, :token)
    username = Keyword.fetch!(opts, :username)
    auth = Keyword.get(opts, :auth, Macro.escape(nil))
    restart = Keyword.get(opts, :restart, Macro.escape(:permanent))

    quote location: :keep do
      @behaviour Telegram.Bot

      @token unquote(token)
      @username unquote(username)
      @auth unquote(auth)

      use Task, restart: unquote(restart)
      import Telegram.Bot.Dsl

      def start() do
        Task.start(Telegram.Bot, :run, [__MODULE__, @token, @username])
      end

      def start_link(_args \\ nil) do
        Task.start_link(Telegram.Bot, :run, [__MODULE__, @token, @username])
      end

      def init() do
        :ok
      end

      cond do
        is_nil(@auth) ->
          def handle_auth(_username) do
            true
          end
        is_list(@auth) ->
          def handle_auth(username) do
            username in @auth
          end
        is_function(@auth) ->
          def handle_auth(username) do
            @auth.(username)
          end
      end

      defoverridable [init: 0, handle_auth: 1]
    end
  end

  @doc false
  def run(module, token, username, offset \\ -1) do
    Logger.debug("Telegram.Bot running: module=#{inspect module}, username=#{inspect username}")

    check_bot(token, username)
    apply(module, :init, [])
    loop(%Telegram.Bot.Context{module: module, token: token, offset: offset})
  end

  defp check_bot(token, username) do
    case Telegram.Api.request(token, "getMe") do
      {:ok, me} ->
        if me["username"] != username do
          raise ArgumentError, message:
            """
            The username associated with the provided token `#{inspect token}` is
            #{inspect me["username"]} and it does not match the configured
            one (#{inspect username}).
            """
        end
      {:error, reason} ->
        cooldown(@retry_quiet_period, "Telegram.Api.request 'getMe' error: #{inspect reason}")
        check_bot(token, username)
    end
  end

  defp loop(context) do
    updates = wait_updates(context)

    halt? =
      try do
        updates
        |> filter_authorized_users(context)
        |> process_updates(context)
      rescue
        Halt -> true
      else
        _ -> false
      end

    if halt? do
      Logger.info("Telegram.Bot HALT.")
    else
      loop(%Context{context | offset: next_update_offset(context, updates)})
    end
  end

  defp next_update_offset(context, updates) do
    if updates == [] do
      context.offset
    else
      List.last(updates)["update_id"] + 1
    end
  end

  defp wait_updates(context) do
    case Telegram.Api.request(context.token, "getUpdates", offset: context.offset, timeout: @poll_timeout) do
      {:ok, updates} ->
        updates
      {:error, reason} ->
        cooldown(@retry_quiet_period, "Telegram.Api.request 'getUpdates' error: #{inspect reason}")
        wait_updates(context)
    end
  end

  defp filter_authorized_users(updates, context) do
    Enum.filter(updates, &(apply(context.module, :handle_auth, [get_from_username(&1)])))
  end

  defp get_from_username(update) do
    # https://core.telegram.org/bots/api#update
    # should be always present, in any type of Update object
    Enum.find_value(update,
      fn
        ({_, %{"from" => %{"username" => username}}}) ->
          username
        (_) ->
          false
      end
    )
  end

  defp process_updates(updates, context) do
    Enum.each(updates, &(process_update(&1, context)))
  end

  defp process_update(update, context) do
    Logger.debug("handle_update: #{inspect update}")
    apply(context.module, :handle_update, [context.token, update])
  end

  defp cooldown(seconds, reason_str) do
    Logger.warn(reason_str)
    Logger.warn("Retry in #{seconds}s.")
    Process.sleep(seconds * 1000)
  end
end

defmodule Telegram.Bot.Dsl do
  @moduledoc """
  Telegram.Bot DSL macros.

  ## Update object
  Every macro inject in the body scope a `update` variable holding
  the received specific update object (Message, InlineQuery, ...),
  with the exception of `any/1` where `update` holds the Update object.

  [Reference: Update](https://core.telegram.org/bots/api#update)
  """

  @doc ~S"""
  Halts the Bot.

  ```elixir
  command "stop", _args do
    halt "user requested to stop the bot"
  end
  ```
  """
  defmacro halt(message) do
    quote do
      raise Telegram.Bot.Halt, unquote(message)
    end
  end

  @doc ~S"""
  Match Telegram "/command arg1 arg2" (with args, if any).

  ```elixir
  command "start", args do
    # ex: telegram -> "/start hello 1"
    #     args = ["hello", "1"]
  end
  ```

  or a set of commands:

  ```elixir
  command ["start", "go"], args do
    # handler code
  end
  ```
  """
  defmacro command(text, args, do: body) when is_binary(text) do
    quote_handle_update_for_command(text, args, body)
  end

  defmacro command(commands, args, do: body) when is_list(commands) do
    Enum.each(commands,
      fn (command) ->
        if not is_binary(command) do
          raise ArgumentError, message: "expected list of commands as strings"
        end
      end
    )
    Enum.map(commands, &(quote_handle_update_for_command(&1, args, body)))
  end

  @doc ~S"""
  Match any other not matched command.

  ```elixir
  command "start", args do
    # handler code
  end

  command unknown do
    # ex: telegram -> "/end hello"
    #     unknown = "end hello"
  end
  ```
  """
  defmacro command(text, do: body) do
    quote_handle_update_for_command(text, body)
  end

  @doc ~S"""
  Match a generic Telegram message.

  ```elixir
  message do
    # ex: telegram -> "go!"
    #     update["text"] = "go!"
  end
  ```

  ## Note:
  Since Telegram commands are just messages starting with "/",
  this can match also commands.
  In general you should put `command/3` before `message/2` clause:

  ```elixir
  command "start", args, do: :something
  command unknown, do: :something_for_unknown_commands
  message do: :something_for_messages
  ```
  """
  defmacro message(do: body) do
    quote_handle_update_for_type("message", body)
  end

  for type <- [:edited_message, :channel_post, :edited_channel_post,
               :callback_query, :shipping_query, :pre_checkout_query] do
    @doc """
    Match a generic Telegram #{type}.

    ```elixir
    #{type} do
      # handler code
    end
    ```
    """
    defmacro unquote(type)(do: body) do
      quote_handle_update_for_type(to_string(unquote(type)), body)
    end
  end

  @doc ~S"""
  Match a Telegram inline_query

  ```elixir
  inline_query query do
    # ex: telegram -> "@your_bot queeery!"
    #     query = "queeery!"
  end
  ```
  """
  defmacro inline_query(query, do: body) do
    quote_handle_update_for_text("inline_query", "query", query, body)
  end

  @doc ~S"""
  Match a Telegram chosen_inline_query

  ```elixir
  chosen_inline_result query do
    # handler code
  end
  ```
  """
  defmacro chosen_inline_result(query, do: body) do
    quote_handle_update_for_text("chosen_inline_result", "query", query, body)
  end

  @doc ~S"""
  Match any Telegram update.
  This should be the very last fallback clause in your bot.

  ```elixir
  any do
    IO.puts("ANY #{inspect update}")
  end
  ```
  """
  defmacro any(do: body) do
    quote_handle_update(body)
  end

  @doc ~S"""
  A small wrapper for `Telegram.Api.request`.
  Autofill the token parameter with the `Telegram.Bot` configured.

  ```elixir
  command "hello", args do
    request "sendMessage", chat_id: update["chat"]["id"],
      text: "Hello #{inspect update["from"]["username"]}"
  end
  ```
  """
  defmacro request(method, options) do
    quote do
      Telegram.Api.request(var!(token__), unquote(method), unquote(options))
    end
  end

  defp quote_handle_update(body) do
    quote do
      def handle_update(var!(token__), var!(update)) do
        _ = var!(token__)
        _ = var!(update)
        unquote(body)
      end
    end
  end

  defp quote_handle_update_for_type(update_type, body) do
    quote do
      def handle_update(var!(token__), %{unquote(update_type) => var!(update)}) do
        _ = var!(token__)
        _ = var!(update)
        unquote(body)
      end
    end
  end

  defp quote_handle_update_for_text(update_type, text_field, text, body) do
    quote do
      def handle_update(var!(token__), %{unquote(update_type) => var!(update)=%{unquote(text_field) => unquote(text)}}) do
        _ = var!(token__)
        _ = var!(update)
        unquote(body)
      end
    end
  end

  defp quote_handle_update_for_command(text, body) do
    quote do
      def handle_update(var!(token__), %{"message" => var!(update)=%{"text" => "/" <> rest}}) do
        _ = var!(update)
        _ = var!(token__)
        unquote(text) = rest
        unquote(body)
      end
    end
  end

  defp quote_handle_update_for_command(text, args, body) do
    quote do
      def handle_update(var!(token__), %{"message" => var!(update)=%{"text" => "/" <> unquote(text)}}) do
        _ = var!(update)
        _ = var!(token__)
        unquote(args) = []
        unquote(body)
      end
      def handle_update(var!(token__), %{"message" => var!(update)=%{"text" => "/" <> unquote(text) <> " " <> rest}}) do
        _ = var!(update)
        _ = var!(token__)
        unquote(args) = String.split(rest)
        unquote(body)
      end
      def handle_update(var!(token__), %{"message" => var!(update)=%{"text" => "/" <> unquote(text) <> "@" <> @username}}) do
        _ = var!(update)
        _ = var!(token__)
        unquote(args) = []
        unquote(body)
      end
      def handle_update(var!(token__), %{"message" => var!(update)=%{"text" => "/" <> unquote(text) <> "@" <> @username <> " " <> rest}}) do
        _ = var!(update)
        _ = var!(token__)
        unquote(args) = String.split(rest)
        unquote(body)
      end
    end
  end
end
