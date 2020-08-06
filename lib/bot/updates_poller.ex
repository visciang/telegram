defmodule Telegram.Bot.UpdatesPoller do
  use Task, restart: :permanent
  require Logger

  # timeout configuration opts unit: seconds
  @get_updates_poll_timeout Application.get_env(:telegram, :get_updates_poll_timeout, 30)
  @on_error_retry_delay Application.get_env(:telegram, :on_error_retry_delay, 5)
  @purge_after @get_updates_poll_timeout * 2

  @type options :: {:purge, boolean()}

  defmodule Context do
    @moduledoc false
    defstruct [:bot_workers_supervisor, :bot_module, :token, :offset]

    @type t :: %__MODULE__{
            bot_workers_supervisor: Supervisor.supervisor(),
            bot_module: module(),
            token: Telegram.Client.token(),
            offset: integer()
          }
  end

  @spec start_link({Supervisor.supervisor(), module(), Telegram.Client.token(), [options()]}) :: {:ok, pid()}
  def start_link({bot_workers_supervisor, bot_module, token, options}) do
    default = [purge: true]
    options = Keyword.merge(default, options)

    Task.start_link(__MODULE__, :run, [
      bot_workers_supervisor,
      bot_module,
      token,
      options[:purge]
    ])
  end

  @doc false
  @spec run(Supervisor.supervisor(), module(), Telegram.Client.token(), boolean()) :: no_return
  def run(bot_workers_supervisor, bot_module, token, purge) do
    Logger.debug("#{__MODULE__} running Bot behaviour #{bot_module}")

    context = %Context{
      bot_workers_supervisor: bot_workers_supervisor,
      bot_module: bot_module,
      token: token,
      offset: nil
    }

    check_bot(token)

    next_offset =
      if purge do
        purge_old_updates(context, @purge_after)
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

  defp process_updates(updates, context) do
    updates |> Enum.reduce(nil, &process_update(&1, &2, context))
  end

  defp process_update(update, _acc, context) do
    Logger.debug("process_update: #{inspect(update)}")

    Task.Supervisor.start_child(
      context.bot_workers_supervisor,
      context.bot_module,
      :handle_update,
      [update, context.token]
    )

    update["update_id"] + 1
  end

  defp cooldown(seconds, reason_str) do
    Logger.warn(reason_str)
    Logger.warn("Retry in #{seconds}s.")
    Process.sleep(seconds * 1000)
  end

  defp purge_old_updates(context, delta) do
    next =
      wait_updates(context)
      |> Enum.reduce_while(nil, &is_old_update(&1, &2, delta))

    case next do
      {:purge, next_offset} ->
        purge_old_updates(%Context{context | offset: next_offset}, delta)

      offset ->
        offset
    end
  end

  defp is_old_update(update, _offset, delta) do
    sent = Telegram.Bot.Utils.get_sent_date(update)

    if sent != nil do
      # sent date is UTC
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