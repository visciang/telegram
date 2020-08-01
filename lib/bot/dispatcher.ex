defmodule Telegram.Bot.Dispatcher do
  use Task, restart: :permanent
  require Logger

  # timeout configuration opts unit: seconds
  @get_updates_poll_timeout Application.get_env(:telegram, :get_updates_poll_timeout, 30)
  @on_error_retry_delay Application.get_env(:telegram, :on_error_retry_delay, 5)
  @purge_after @get_updates_poll_timeout * 2

  @type whitelist :: [String.t()] | nil
  @type options :: {:purge, boolean()} | {:whitelist, whitelist()}

  defmodule Context do
    @moduledoc false
    defstruct [:bot_worker_supervisor, :bot_module, :token, :offset, :whitelist]

    @type t :: %__MODULE__{
            bot_worker_supervisor: Supervisor.supervisor(),
            bot_module: module(),
            token: Telegram.Client.token(),
            offset: integer(),
            whitelist: Telegram.Bot.Dispatcher.whitelist()
          }
  end

  @spec start_link({Supervisor.supervisor(), module(), Telegram.Client.token(), [options()]}) ::
          {:ok, pid()}
  def start_link({bot_worker_supervisor, bot_module, token, options}) do
    default = [purge: true, whitelist: nil]
    options = Keyword.merge(default, options)

    Task.start_link(__MODULE__, :run, [
      bot_worker_supervisor,
      bot_module,
      token,
      options[:purge],
      options[:whitelist]
    ])
  end

  @doc false
  def run(bot_worker_supervisor, bot_module, token, purge, whitelist) do
    Logger.debug("#{__MODULE__} running Bot behaviour #{bot_module}")

    context = %Context{
      bot_worker_supervisor: bot_worker_supervisor,
      bot_module: bot_module,
      token: token,
      offset: nil,
      whitelist: whitelist
    }

    check_bot(token)

    next_offset =
      if purge do
        purge_old_messages(context, @purge_after)
      else
        nil
      end

    loop(%Context{context | offset: next_offset})
  end

  defp check_bot(token) do
    case Telegram.Api.request(token, "getMe") do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        cooldown(
          @on_error_retry_delay,
          "Telegram.Api.request 'getMe' error: #{inspect(reason)}"
        )

        check_bot(token)
    end
  end

  defp loop(context) do
    updates = wait_updates(context)

    next_offset = process_updates(updates, context)
    loop(%Context{context | offset: next_offset})
  end

  defp wait_updates(context) do
    opts_offset = if context.offset != nil, do: [offset: context.offset], else: []
    opts = [timeout: @get_updates_poll_timeout] ++ opts_offset

    case Telegram.Api.request(context.token, "getUpdates", opts) do
      {:ok, updates} ->
        updates

      {:error, reason} ->
        cooldown(
          @on_error_retry_delay,
          "Telegram.Api.request 'getUpdates' error: #{inspect(reason)}"
        )

        wait_updates(context)
    end
  end

  defp authorized?(_username, nil), do: true
  defp authorized?(username, whitelist), do: username in whitelist

  defp get_from_username(update) do
    # https://core.telegram.org/bots/api#update
    # should be always present, in any _type of Update object
    Enum.find_value(update, fn
      {_update_type, %{"from" => %{"username" => username}}} ->
        username

      _ ->
        false
    end)
  end

  defp get_sent_date(update) do
    Enum.find_value(update, fn
      {_update_type, %{"date" => date}} ->
        date

      _ ->
        nil
    end)
  end

  defp process_updates(updates, context) do
    updates |> Enum.reduce(nil, &process_update(&1, &2, context))
  end

  def process_update(update, _acc, context) do
    Logger.debug("process_update: #{inspect(update)}")

    username = get_from_username(update)

    if authorized?(username, context.whitelist) do
      Task.Supervisor.start_child(
        context.bot_worker_supervisor,
        context.bot_module,
        :handle_update,
        [update, context.token]
      )
    else
      Logger.debug("Unauthorized user message (#{username})")
    end

    update["update_id"] + 1
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
