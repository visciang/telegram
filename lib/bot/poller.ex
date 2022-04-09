defmodule Telegram.Bot.Poller do
  use Task, restart: :permanent
  use Retry
  require Logger
  alias Telegram.Bot.Poller
  alias Telegram.Types

  @type handle_update :: (update :: Types.update(), token :: Types.token() -> any())

  defmodule Context do
    @moduledoc false
    defstruct [:handle_update, :token, :offset]

    @type t :: %__MODULE__{
            handle_update: Poller.handle_update(),
            token: Types.token(),
            offset: integer()
          }
  end

  @spec start_link({handle_update(), Types.token()}) :: {:ok, pid()}
  def start_link({handle_update, token}) do
    Task.start_link(__MODULE__, :run, [handle_update, token])
  end

  @doc false
  @spec run(handle_update(), Types.token()) :: no_return
  def run(handle_update, token) do
    Logger.debug("#{__MODULE__} running with token '#{token}'")

    context = %Context{
      handle_update: handle_update,
      token: token,
      offset: nil
    }

    loop(%Context{context | offset: nil})
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

  defp conf_get_updates_poll_timeout do
    # timeout configuration opts unit: seconds
    Application.get_env(:telegram, :get_updates_poll_timeout, 30)
  end
end
