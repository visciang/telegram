defmodule Telegram.Bot.Poller do
  use Task, restart: :permanent
  use Retry
  require Logger
  alias Telegram.Bot.{Poller, Utils}

  @type options :: {:purge, boolean()}
  @type handle_update :: (update :: Telegram.Types.update(), token :: Telegram.Types.token() -> nil)

  defmodule Context do
    @moduledoc false
    defstruct [:handle_update, :token, :offset]

    @type t :: %__MODULE__{
            handle_update: Poller.handle_update(),
            token: Telegram.Types.token(),
            offset: integer()
          }
  end

  @spec start_link({handle_update(), Telegram.Types.token(), [options()]}) :: {:ok, pid()}
  def start_link({handle_update, token, options}) do
    default = [purge: true]
    options = Keyword.merge(default, options)

    Task.start_link(__MODULE__, :run, [
      handle_update,
      token,
      options[:purge]
    ])
  end

  @doc false
  @spec run(handle_update(), Telegram.Types.token(), boolean()) :: no_return
  def run(handle_update, token, purge) do
    Logger.debug("#{__MODULE__} running with token '#{token}'")

    context = %Context{
      handle_update: handle_update,
      token: token,
      offset: nil
    }

    next_offset =
      if purge do
        purge_old_updates(context, conf_purge_after())
      else
        nil
      end

    loop(%Context{context | offset: next_offset})
  end

  defp loop(context) do
    updates = wait_updates(context)

    next_offset = process_updates(updates, context)
    loop(%Context{context | offset: next_offset})
  end

  defp wait_updates(context) do
    opts_offset = if context.offset != nil, do: [offset: context.offset], else: []
    opts = [timeout: conf_get_updates_poll_timeout()] ++ opts_offset

    retry with: exponential_backoff() |> expiry(conf_get_updates_poll_timeout() * 1_000) do
      Telegram.Api.request(context.token, "getUpdates", opts)
    after
      {:ok, updates} ->
        updates
    else
      error ->
        # coveralls-ignore-start
        raise "Telegram.Api.request 'getUpdates' error: #{inspect(error)}"
        # coveralls-ignore-stop
    end
  end

  defp process_updates(updates, context) do
    updates |> Enum.reduce(nil, &process_update(&1, &2, context))
  end

  defp process_update(update, _acc, context) do
    Logger.debug("[#{context.token}] process_update: #{inspect(update)}")

    context.handle_update.(update, context.token)
    update["update_id"] + 1
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
    Utils.get_sent_date(update)
    |> case do
      nil ->
        {:halt, update["update_id"]}

      {:ok, sent} ->
        # sent date is UTC
        now = DateTime.utc_now()

        if DateTime.diff(now, sent, :second) > delta do
          Logger.debug("Purge old message (sent: #{inspect(sent)}, now: #{inspect(now)})")
          {:cont, {:purge, update["update_id"] + 1}}
        else
          {:halt, update["update_id"]}
        end
    end
  end

  defp conf_get_updates_poll_timeout do
    # timeout configuration opts unit: seconds
    Application.get_env(:telegram, :get_updates_poll_timeout, 30)
  end

  defp conf_purge_after do
    conf_get_updates_poll_timeout() * 2
  end
end
