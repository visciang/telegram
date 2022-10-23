defmodule Telegram.Webhook do
  @moduledoc """
  Telegram Webhook supervisor.

  ## Usage

  In you app supervisor tree:

  ```elixir
  webhook_config = [
    host: "myapp.public-domain.com",
    port: 443,
    local_port: 4_000
  ]

  bot_config = [
    token: Application.fetch_env!(:my_app, :token_counter_bot),
    max_bot_concurrency: Application.fetch_env!(:my_app, :max_bot_concurrency)
  ]

  children = [
    {Telegram.Webhook, config: webhook_config, bots: [{MyApp.Bot, bot_config}]}
    ...
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
  ```

  ## Ref
  - https://core.telegram.org/bots/api#setwebhook
  - https://core.telegram.org/bots/webhooks
  """

  alias Telegram.Types
  require Logger

  use Supervisor

  @defautl_port 443
  @defautl_local_port 4000
  @defautl_max_connections 40

  @default_config [
    port: @defautl_port,
    local_port: @defautl_local_port,
    max_connections: @defautl_max_connections,
    set_webhook: true
  ]

  @typedoc """
  Webhook configuration.

  - `host`: (reverse proxy) hostname of the HTTPS webhook url (required)
  - `port`: (reverse proxy) port of the HTTPS webhook url (optional, default: #{@defautl_port})
  - `local_port`: (backend) port of the application HTTP web server (optional, default: #{@defautl_local_port})
  - `max_connections`: maximum allowed number of simultaneous connections to the webhook for update delivery (optional, defaults #{@defautl_max_connections})
  """
  @type config :: [
          host: String.t(),
          port: :inet.port_number(),
          local_port: :inet.port_number(),
          max_connections: 1..100,
          set_webhook: boolean()
        ]

  @spec start_link(config: config(), bots: [Types.bot_spec()]) :: Supervisor.on_start()
  def start_link(config: config, bots: bot_specs) do
    Supervisor.start_link(__MODULE__, {config, bot_specs}, name: __MODULE__)
  end

  @impl Supervisor
  def init({config, bot_specs}) do
    config = Keyword.merge(@default_config, config)
    host = Keyword.fetch!(config, :host)
    port = Keyword.fetch!(config, :port)
    local_port = Keyword.fetch!(config, :local_port)
    max_connections = Keyword.fetch!(config, :max_connections)
    set_webhook? = Keyword.fetch!(config, :set_webhook)

    bot_routing_map =
      bot_specs
      |> Map.new(fn {bot_behaviour_mod, opts} ->
        token = Keyword.fetch!(opts, :token)
        {token, bot_behaviour_mod}
      end)

    Enum.each(bot_specs, fn {bot_behaviour_mod, opts} ->
      token = Keyword.fetch!(opts, :token)
      url = %URI{scheme: "https", host: host, path: "/#{token}", port: port} |> to_string()

      Logger.info("Running in webhook mode #{url}", bot: bot_behaviour_mod, token: token)

      if set_webhook? do
        # coveralls-ignore-start
        set_webhook(token, url, max_connections)
        # coveralls-ignore-stop
      else
        Logger.info("Skipped setWebhook as requested via config.set_webhook", bot: bot_behaviour_mod, token: token)
      end
    end)

    plug_cowboy_spec =
      {Plug.Cowboy,
       [
         scheme: :http,
         plug: {Telegram.Webhook.Router, [bot_routing_map: bot_routing_map]},
         options: [
           port: local_port
         ]
       ]}

    children = bot_specs ++ [plug_cowboy_spec]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # coveralls-ignore-start

  defp set_webhook(token, url, max_connections) do
    opts = [url: url, max_connections: max_connections]
    {:ok, _} = Telegram.Api.request(token, "setWebhook", opts)
  end

  # coveralls-ignore-stop
end

defmodule Telegram.Webhook.Router do
  @moduledoc false

  require Logger

  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason
  plug :dispatch, builder_opts()

  post "/:token" do
    update = conn.body_params
    bot_dispatch_behaviour = Map.get(opts[:bot_routing_map], token)

    Logger.debug("received update: #{inspect(update)}", bot: bot_dispatch_behaviour, token: token)

    if bot_dispatch_behaviour == nil do
      Plug.Conn.send_resp(conn, :not_found, "")
    else
      bot_dispatch_behaviour.dispatch_update(update, token)
      Plug.Conn.send_resp(conn, :ok, "")
    end
  end

  # coveralls-ignore-start

  match _ do
    Plug.Conn.send_resp(conn, :not_found, "")
  end

  # coveralls-ignore-stop
end
