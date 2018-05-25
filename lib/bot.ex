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
      request("sendMessage",
        chat_id: update["chat"]["id"],
        text: "ciao! #{inspect args}")
    end

    command unknown do
      request("sendMessage", chat_id: update["chat"]["id"],
        text: "Unknow command `#{unknown}`")
    end

    message do
      request("sendMessage", chat_id: update["chat"]["id"],
        text: "Hey! You sent me a message: #{inspect update}")
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
    purge: boolean()                # purge old messages at startup, default: false
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
    @type t :: %__MODULE__{module: module, token: String.t(), offset: integer}
  end

  defmodule Halt do
    @moduledoc false
    defexception [:message, :system_stop]
  end

  @callback init() :: any
  @callback handle_auth(username :: String.t()) :: boolean
  @callback handle_update(token :: String.t(), update :: map) :: any

  # timeout configuration opts unit: seconds
  @get_updates_poll_timeout Application.get_env(:telegram, :get_updates_poll_timeout, 30)
  @on_error_retry_quiet_period Application.get_env(:telegram, :on_error_retry_quiet_period, 5)
  @purge_after @get_updates_poll_timeout * 2

  defmacro __using__(opts) do
    token = Keyword.fetch!(opts, :token)
    username = Keyword.fetch!(opts, :username)
    auth = Keyword.get(opts, :auth, Macro.escape(nil))
    purge = Keyword.get(opts, :purge, Macro.escape(false))
    restart = Keyword.get(opts, :restart, Macro.escape(:permanent))

    quote location: :keep do
      @behaviour Telegram.Bot

      @token unquote(token)
      @username unquote(username)
      @auth unquote(auth)
      @purge unquote(purge)

      use Task, restart: unquote(restart)
      import Telegram.Bot.Dsl

      def start() do
        Task.start(Telegram.Bot, :run, [__MODULE__, @token, @username, @purge])
      end

      def start_link(_args \\ nil) do
        Task.start_link(Telegram.Bot, :run, [__MODULE__, @token, @username, @purge])
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

      defoverridable init: 0, handle_auth: 1
    end
  end

  @doc false
  def run(module, token, username, purge) do
    Logger.debug("Telegram.Bot (#{module}) running: username=#{username} purge=#{purge}")

    context = %Context{module: module, token: token, offset: nil}

    check_bot(token, username)

    next_offset =
      if purge do
        purge_old_messages(context, @purge_after)
      else
        nil
      end

    module.init()
    loop(%Context{context | offset: next_offset})
  end

  defp check_bot(token, username) do
    case Telegram.Api.request(token, "getMe") do
      {:ok, me} ->
        if me["username"] != username do
          raise ArgumentError,
            message: """
            The username associated with the provided token `#{token}` is
            #{me["username"]} and it does not match the configured
            one (#{username}).
            """
        end

      {:error, reason} ->
        cooldown(
          @on_error_retry_quiet_period,
          "Telegram.Api.request 'getMe' error: #{inspect(reason)}"
        )

        check_bot(token, username)
    end
  end

  defp loop(context) do
    updates = wait_updates(context)

    case process_updates(updates, context) do
      {:bot_halt, last_offset, system_stop} ->
        confirm_message(last_offset, context)
        Logger.info("Telegram.Bot HALT.")

        if system_stop do
          System.stop()
        end

      next_offset ->
        loop(%Context{context | offset: next_offset})
    end
  end

  defp wait_updates(context) do
    opts_offset = if context.offset != nil, do: [offset: context.offset], else: []
    opts = [timeout: @get_updates_poll_timeout] ++ opts_offset

    case Telegram.Api.request(context.token, "getUpdates", opts) do
      {:ok, updates} ->
        updates

      {:error, reason} ->
        cooldown(
          @on_error_retry_quiet_period,
          "Telegram.Api.request 'getUpdates' error: #{inspect(reason)}"
        )

        wait_updates(context)
    end
  end

  defp confirm_message(offset, context) do
    Telegram.Api.request(context.token, "getUpdates", limit: 1, offset: offset + 1, timeout: 0)
    :ok
  end

  defp authorized?(update, context) do
    context.module.handle_auth(get_from_username(update))
  end

  defp get_from_username(update) do
    # https://core.telegram.org/bots/api#update
    # should be always present, in any type of Update object
    Enum.find_value(update, fn
      {_, %{"from" => %{"username" => username}}} ->
        username

      _ ->
        false
    end)
  end

  defp get_sent_date(update) do
    Enum.find_value(update, fn
      {_, %{"date" => date}} ->
        date

      _ ->
        nil
    end)
  end

  defp process_updates(updates, context) do
    updates |> Enum.reduce_while(nil, &process_update(&1, &2, context))
  end

  def process_update(update, _acc, context) do
    Logger.debug("process_update: #{inspect(update)}")

    if authorized?(update, context) do
      try do
        context.module.handle_update(context.token, update)
      rescue
        e in Halt -> {:halt, {:bot_halt, update["update_id"], e.system_stop}}
      else
        _ -> {:cont, update["update_id"] + 1}
      end
    else
      Logger.debug("Unauthorized user message (#{get_from_username(update)})")
      {:cont, update["update_id"] + 1}
    end
  end

  defp cooldown(seconds, reason_str) do
    Logger.warn(reason_str)
    Logger.warn("Retry in #{seconds}s.")
    Process.sleep(seconds * 1000)
  end

  defp purge_old_messages(context, delta) do
    next =
      wait_updates(context)
      |> Enum.reduce_while(nil, &old_message(&1, &2, delta))

    case next do
      {:purge, next_offset} ->
        purge_old_messages(%Context{context | offset: next_offset}, delta)

      offset ->
        offset
    end
  end

  defp old_message(update, _offset, delta) do
    sent_unix_time = get_sent_date(update)

    if sent_unix_time != nil do
      # sent date is UTC
      sent = DateTime.from_unix!(sent_unix_time, :second)
      now = DateTime.utc_now()

      if DateTime.diff(now, sent, :second) > delta do
        Logger.debug("Purge old message (sent: #{inspect(sent)}, now: #{inspect(now)})")
        {:cont, {:purge, update["update_id"] + 1}}
      else
        {:halt, update["update_id"]}
      end
    else
      {:halt, update["update_id"]}
    end
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
  command "stop_bot", _args do
    halt("user requested to stop the bot")
  end

  command "stop_system", _args do
    halt("user requested to stop the system", true)
  end
  ```
  """
  @spec halt(message :: String.t()) :: no_return()
  @spec halt(message :: String.t(), system_stop :: boolean()) :: no_return()
  def halt(message, system_stop \\ false) do
    raise(Telegram.Bot.Halt, message: message, system_stop: system_stop)
  end

  @doc ~S"""
  Match Telegram "/command arg1 arg2" (with args, if any).

  ```elixir
  command "start", args do
    # ex: telegram -> "/start hello 1"
    #     args = ["hello", "1"]
  end
  ```

  ```elixir
  command "start", ["hello", "2"] do
    # ex: telegram -> "/start hello 2"
    #
    # NOTE: the args are not whitespace normalized (stripped)
    #       so the pattern matching is an identity match with the string
    #       "/start hello 2" (one space char separator),
    #       ie. "/start   hello 2" won't match
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
    Enum.each(commands, fn command ->
      if not is_binary(command) do
        raise ArgumentError, message: "expected list of commands as strings"
      end
    end)

    Enum.map(commands, &quote_handle_update_for_command(&1, args, body))
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
  Match Telegram callback_data "/callback_query arg1 arg2" (with args, if any).

  ```elixir
  callback_query "set_language", args do
    # ex: callback_data -> "/set_language en 1"
    #     args = ["en", "1"]
  end
  ```

  ```elixir
  callback_query "set_language", ["fr", "2"] do
    # ex: callback_data -> "/set_language fr 2"
  end
  ```

  or a set of commands:

  ```elixir
  callback_query ["set_language", "set_alternative_language"], args do
    # handler code
  end
  ```
  """

  defmacro callback_query(text, args, do: body) when is_binary(text) do
    quote_handle_update_for_callback_query(text, args, body)
  end

  defmacro callback_query(callback_queries, args, do: body) when is_list(callback_queries) do
    Enum.each(callback_queries, fn callback_query ->
      if not is_binary(callback_query) do
        raise ArgumentError, message: "expected list of callback_queries as strings"
      end
    end)

    Enum.map(callback_queries, &quote_handle_update_for_callback_query(&1, args, body))
  end

  @doc ~S"""
  Match any other not matched callback_query.

  ```elixir
  callback_query "set_some", args do
    # handler code
  end

  callback_query unknown do
    # ex: telegram -> "/end hello"
    #     unknown = "end hello"
  end
  ```
  """

  defmacro callback_query(text, do: body) do
    quote_handle_update_for_callback_query(text, body)
  end

  @doc ~S"""
  Match callback_query as a generic Telegram message for retrocompatibility.

  ```elixir
  callback_query do
    # handler code
  end
  ```
  """

  defmacro callback_query(do: body) do
    quote_handle_update_for_callback_query(body)
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

  for type <- [
        :edited_message,
        :channel_post,
        :edited_channel_post,
        :shipping_query,
        :pre_checkout_query
      ] do
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
      def handle_update(var!(token__), %{
            unquote(update_type) => var!(update) = %{unquote(text_field) => unquote(text)}
          }) do
        _ = var!(token__)
        _ = var!(update)
        unquote(body)
      end
    end
  end

  defp quote_handle_update_for_command(text, body) do
    quote do
      def handle_update(var!(token__), %{"message" => var!(update) = %{"text" => "/" <> rest}}) do
        _ = var!(update)
        _ = var!(token__)
        unquote(text) = rest
        unquote(body)
      end
    end
  end

  defp quote_handle_update_for_command(text, args, body) do
    if is_list(args) and Enum.all?(args, &is_binary/1) do
      args_string = args_to_string(args)

      quote do
        def handle_update(var!(token__), %{
              "message" =>
                var!(update) = %{"text" => "/" <> unquote(text) <> unquote(args_string)}
            }) do
          _ = var!(update)
          _ = var!(token__)
          unquote(body)
        end

        def handle_update(var!(token__), %{
              "message" =>
                var!(update) = %{
                  "text" => "/" <> unquote(text) <> "@" <> @username <> unquote(args_string)
                }
            }) do
          _ = var!(update)
          _ = var!(token__)
          unquote(body)
        end
      end
    else
      quote do
        def handle_update(var!(token__), %{
              "message" => var!(update) = %{"text" => "/" <> unquote(text)}
            }) do
          _ = var!(update)
          _ = var!(token__)
          unquote(args) = []
          unquote(body)
        end

        def handle_update(var!(token__), %{
              "message" => var!(update) = %{"text" => "/" <> unquote(text) <> " " <> rest}
            }) do
          _ = var!(update)
          _ = var!(token__)
          unquote(args) = String.split(rest)
          unquote(body)
        end

        def handle_update(var!(token__), %{
              "message" => var!(update) = %{"text" => "/" <> unquote(text) <> "@" <> @username}
            }) do
          _ = var!(update)
          _ = var!(token__)
          unquote(args) = []
          unquote(body)
        end

        def handle_update(var!(token__), %{
              "message" =>
                var!(update) = %{
                  "text" => "/" <> unquote(text) <> "@" <> @username <> " " <> rest
                }
            }) do
          _ = var!(update)
          _ = var!(token__)
          unquote(args) = String.split(rest)
          unquote(body)
        end
      end
    end
  end

  # retrocompatibility
  defp quote_handle_update_for_callback_query(body) do
    quote_handle_update_for_type("callback_query", body)
  end

  defp quote_handle_update_for_callback_query(text, body) do
    quote do
      def handle_update(var!(token__), %{
            "callback_query" => var!(update) = %{"data" => "/" <> rest}
          }) do
        _ = var!(update)
        _ = var!(token__)
        unquote(text) = rest
        unquote(body)
      end
    end
  end

  defp quote_handle_update_for_callback_query(text, args, body) when is_list(args) do
    args_string = args_to_string(args)

    quote do
      def handle_update(var!(token__), %{
            "callback_query" =>
              var!(update) = %{"data" => "/" <> unquote(text) <> unquote(args_string)}
          }) do
        _ = var!(update)
        _ = var!(token__)
        unquote(body)
      end
    end
  end

  defp quote_handle_update_for_callback_query(text, args, body) do
    quote do
      def handle_update(var!(token__), %{
            "callback_query" => var!(update) = %{"data" => "/" <> unquote(text) <> " " <> rest}
          }) do
        _ = var!(update)
        _ = var!(token__)
        unquote(args) = String.split(rest)
        unquote(body)
      end
    end
  end

  defp args_to_string([]), do: ""

  defp args_to_string(args) do
    " " <> Enum.join(args, " ")
  end
end
