defmodule Telegram.Webhook do
  @moduledoc """
  Telegram Webhook supervisor.

  ## Usage:

  In you app supervisor tree:

  ```elixir
  cert_dir = Application.app_dir(:my_app, "priv/cert")

  webhook_config = [
    set_webhook: false,
    certfile: Path.join(cert_dir, "myapp.pem"),
    keyfile: Path.join(cert_dir, "myapp_key.pem")
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

  ## Ref:
  - https://core.telegram.org/bots/api#setwebhook
  - https://core.telegram.org/bots/webhooks
  """

  alias Telegram.Types
  require Logger

  use Supervisor

  @typedoc """
  Webhook configuration.

  - `host`: hostname of the HTTPS webhook url (optional, default: "localhost")
  - `port`: port of the HTTPS webhook url (optional, default: 8443)
  - `max_connections`: maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery (optional, defaults 40)
  - `certfile`: absolute path to your public key certificate (required)
  - `keyfile`: absolute path to your private key (required)

  NOTE:

  Self-signed certificate can be used.
  Uou can generate a selfsigned certificate with the x509 hex package
  (`mix x509.gen.selfsigned HOSTNAME`).
  """
  @type config :: [
          host: String.t(),
          port: :inet.port_number(),
          max_connections: 1..100,
          certfile: String.t(),
          keyfile: String.t(),
          set_webhook: boolean()
        ]

  @default_config [
    host: "localhost",
    port: 8443,
    max_connections: 40,
    set_webhook: true
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
    max_connections = Keyword.fetch!(config, :max_connections)
    certfile = Keyword.fetch!(config, :certfile)
    keyfile = Keyword.fetch!(config, :keyfile)
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
        set_webhook(token, url, max_connections, certfile)
        # coveralls-ignore-end
      else
        Logger.info("Skipped setWebhook as requested via config.set_webhook", bot: bot_behaviour_mod, token: token)
      end
    end)

    plug_cowboy_spec =
      {Plug.Cowboy,
       [
         scheme: :https,
         plug: {Telegram.Webhook.Router, [bot_routing_map: bot_routing_map]},
         options: [
           port: port,
           certfile: certfile,
           keyfile: keyfile
         ]
       ]}

    children = bot_specs ++ [plug_cowboy_spec]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # coveralls-ignore-start

  defp set_webhook(token, url, max_connections, certfile) do
    opts = [url: url, max_connections: max_connections, certificate: {:file, certfile}]
    {:ok, _} = Telegram.Api.request(token, "setWebhook", opts)
  end

  # coveralls-ignore-end
end

defmodule Telegram.Webhook.Router do
  @moduledoc """
  Telegram Webhook plug router.
  """

  require Logger

  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason
  plug :logger
  plug :dispatch, builder_opts()

  post "/:token" do
    update = conn.body_params
    bot_behaviour_mod = Map.get(opts[:bot_routing_map], token)

    if bot_behaviour_mod == nil do
      Plug.Conn.send_resp(conn, :not_found, "")
    else
      bot_behaviour_mod.dispatch_update(update, token)
      Plug.Conn.send_resp(conn, :ok, "")
    end
  end

  # coveralls-ignore-start

  match _ do
    Plug.Conn.send_resp(conn, :not_found, "")
  end

  # coveralls-ignore-end

  def logger(conn, _opts) do
    token = conn.path_params["token"]
    update = conn.body_params

    Logger.debug("received update: #{inspect(update)}", token: token)

    conn
  end
end
