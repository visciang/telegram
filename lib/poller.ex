defmodule Telegram.Poller do
  @moduledoc """
  Telegram poller supervisor.

  ## Usage:

  In you app supervisor tree:

  ```elixir
  bot_config = [
    token: Application.fetch_env!(:my_app, :token_counter_bot),
    max_bot_concurrency: Application.fetch_env!(:my_app, :max_bot_concurrency)
  ]

  children = [
    {Telegram.Poller, bots: [{MyApp.Bot, bot_config}]}
    ...
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
  ```
  """

  alias Telegram.Bot.Utils
  alias Telegram.{Poller, Types}

  use Supervisor

  @spec start_link(bots: [Types.bot_spec()]) :: Supervisor.on_start()
  def start_link(bots: bot_specs) do
    Supervisor.start_link(__MODULE__, bot_specs, name: __MODULE__)
  end

  @impl Supervisor
  def init(bot_specs) do
    pollers =
      Enum.map(bot_specs, fn {bot_behaviour_mod, opts} ->
        token = Keyword.fetch!(opts, :token)
        name = Utils.name(Poller.Task, token)

        Supervisor.child_spec({Poller.Task, {bot_behaviour_mod, token}}, id: name)
      end)

    children = bot_specs ++ pollers
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Telegram.Poller.Task do
  @moduledoc """
  Telegram "getUpdates()" poller task.
  """

  alias Telegram.{Poller, Types}
  require Logger

  use Task, restart: :permanent
  use Retry

  @type dispatch_update :: (Types.update(), Types.token() -> any())

  defmodule Context do
    @moduledoc false
    defstruct [:dispatch_update, :token, :offset]

    @type t :: %__MODULE__{
            dispatch_update: Poller.Task.dispatch_update(),
            token: Types.token(),
            offset: integer()
          }
  end

  @spec start_link({module(), Types.token()}) :: {:ok, pid()}
  def start_link({bot_behaviour_mod, token}) do
    Task.start_link(__MODULE__, :run, [bot_behaviour_mod, token])
  end

  @doc false
  @spec run(module(), Types.token()) :: no_return()
  def run(bot_behaviour_module, token) do
    Logger.metadata(bot: bot_behaviour_module, token: token)
    Logger.info("Running in polling mode")

    set_polling(token)

    context = %Context{
      dispatch_update: &bot_behaviour_module.dispatch_update/2,
      token: token,
      offset: nil
    }

    loop(%Context{context | offset: nil})
  end

  defp set_polling(token) do
    {:ok, %{"url" => url}} = Telegram.Api.request(token, "getWebhookInfo")

    if url != "" do
      Logger.info("Found active webhook (url: #{url})")
      {:ok, true} = Telegram.Api.request(token, "deleteWebhook")
      Logger.info("Webhook deleted")
    end
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
    Logger.debug("process_update: #{inspect(update)}")

    context.dispatch_update.(update, context.token)
    update["update_id"] + 1
  end

  defp conf_get_updates_poll_timeout do
    # timeout configuration opts unit: seconds
    Application.get_env(:telegram, :get_updates_poll_timeout, 30)
  end
end
