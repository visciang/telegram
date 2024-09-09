defmodule Telegram.Poller do
  @moduledoc """
  Telegram poller supervisor.

  ## Usage

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
    assert_tesla_adapter_config()

    Supervisor.start_link(__MODULE__, bot_specs, name: __MODULE__)
  end

  @impl Supervisor
  def init(bot_specs) do
    pollers =
      Enum.map(bot_specs, fn {bot_behaviour_mod, opts} ->
        token = Keyword.fetch!(opts, :token)
        id = Utils.name(Poller.Task, token)

        Supervisor.child_spec({Poller.Task, {bot_behaviour_mod, token}}, id: id)
      end)

    children = bot_specs ++ pollers
    Supervisor.init(children, strategy: :one_for_one)
  end

  # coveralls-ignore-start

  def assert_tesla_adapter_config do
    if Application.get_env(:tesla, :adapter) == nil do
      raise """
      The tesla adapter has not been configured. This will defaults to the built-in erlang :httpc module.

      Please configure a production ready client, for instance:

      config :tesla, adapter: {Tesla.Adapter.Hackney, [recv_timeout: 40_000]}
      """
    end

    # coveralls-ignore-stop
  end
end

defmodule Telegram.Poller.Task do
  @moduledoc false

  alias Telegram.Bot.Dispatch
  alias Telegram.Types
  import Telegram.Utils, only: [retry: 1]
  require Logger

  use Task, restart: :permanent

  defmodule Context do
    @moduledoc false

    @enforce_keys [:dispatch, :token, :offset]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            dispatch: Dispatch.t(),
            token: Types.token(),
            offset: nil | integer()
          }
  end

  @spec start_link({Dispatch.t(), Types.token()}) :: {:ok, pid()}
  def start_link({bot_dispatch_behaviour, token}) do
    Task.start_link(__MODULE__, :run, [bot_dispatch_behaviour, token])
  end

  @doc false
  @spec run(Dispatch.t(), Types.token()) :: no_return()
  def run(bot_dispatch_behaviour, token) do
    Logger.metadata(bot: bot_dispatch_behaviour)
    Logger.info("Running in polling mode")

    set_polling(token)

    context = %Context{
      dispatch: bot_dispatch_behaviour,
      token: token,
      offset: nil
    }

    loop(%Context{context | offset: nil})
  end

  defp set_polling(token) do
    Logger.info("Checking webhook mode is not active...")

    {:ok, %{"url" => url}} = retry(fn -> Telegram.Api.request(token, "getWebhookInfo") end)

    if url != "" do
      Logger.info("Found active webhook (url: #{url})")
      {:ok, true} = retry(fn -> Telegram.Api.request(token, "deleteWebhook") end)
      Logger.info("Webhook deleted")
    end
  end

  defp loop(%Context{} = context) do
    updates = wait_updates(context)

    next_offset = process_updates(updates, context)
    loop(%Context{context | offset: next_offset})
  end

  defp wait_updates(%Context{} = context) do
    opts_offset = if context.offset != nil, do: [offset: context.offset], else: []
    opts = [timeout: conf_get_updates_poll_timeout_s()] ++ opts_offset

    case Telegram.Api.request(context.token, "getUpdates", opts) do
      {:ok, updates} ->
        updates

      error ->
        # coveralls-ignore-start
        raise "Telegram.Api.request 'getUpdates' error: #{inspect(error)}"
        # coveralls-ignore-stop
    end
  end

  defp process_updates(updates, %Context{} = context) do
    updates |> Enum.reduce(nil, &process_update(&1, &2, context))
  end

  defp process_update(update, _acc, %Context{} = context) do
    Logger.debug("process_update: #{inspect(update)}")

    context.dispatch.dispatch_update(update, context.token)
    update["update_id"] + 1
  end

  defp conf_get_updates_poll_timeout_s do
    # timeout configuration opts unit: seconds
    Application.get_env(:telegram, :get_updates_poll_timeout_s, 30)
  end
end
