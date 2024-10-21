defmodule Telegram.Webhook do
  @moduledoc """
  Telegram Webhook supervisor.

  This modules can the used to start a webserver exposing a webhoook endpoint
  where the telegram server can push updates for your BOT.
  On start the webhook address for the BOT is posted to the telegram server
  via the [`setWebHook`](https://core.telegram.org/bots/api#setwebhook) method.

  ## Usage

  ### WebServer adapter

  Two `Plug` compatible webserver are supported:

  - `Telegram.WebServer.Bandit` (default): use `Bandit`
  - `Telegram.WebServer.Cowboy`: use `Plug.Cowboy`

  You should configure the desired webserver adapter in you app configuration:

  ```elixir
  config :telegram,
    webserver: Telegram.WebServer.Bandit

  # OR

  config :telegram,
    webserver: Telegram.WebServer.Cowboy
  ```

  and include in you dependencies one of:

  ```elixir
  {:plug_cowboy, "~> 2.5"}

  # OR

  {:bandit, "~> 1.0"}
  ```

  ### Supervision tree

  In you app supervision tree:

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

  # Direct `Phoenix` / `Plug` integration

  To integrate the webhook in a `Phoenix` / `Plug` based application facing internet,
  configure a `nil`, telegram webserver

  ```elixir
  config :telegram,
    webserver: nil
  ```

  In you app supervision tree:

  ```elixir
  webhook_config = [
    host: "myapp.public-domain.com",
    port: 443
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

  In your app `Phoenix` / `Plug` router:

  ```elixir
  defmodule App.Router do
    use Plug.Router

    # ... my app routes ...

    post "/__telegram_webhook__/:token" do
      Telegram.Webhook.post_webhook(conn, token)
    end
  end
  ```
  """

  alias Telegram.Types
  import Telegram.Utils, only: [retry: 1]
  require Logger

  use Supervisor

  @default_scheme "https"
  @default_port 443
  @default_local_port 4000
  @default_max_connections 40

  @default_config [
    scheme: @default_scheme,
    port: @default_port,
    local_port: @default_local_port,
    max_connections: @default_max_connections,
    set_webhook: true
  ]

  @typedoc """
  Webhook configuration.

  - `scheme`: webhook server connection type - "http" or "https" (optional, default: #{@default_scheme})
  - `host`: hostname of the webhook url (required)
  - `port`: port of the webhook url (optional, default: #{@default_port})
  - `local_port`: (backend) port of the application HTTP web server.
    Used only if `telegram.webhook` is configured (optional, default: #{@default_local_port})
  - `max_connections`: maximum allowed number of simultaneous connections to the webhook for update delivery (optional, defaults #{@default_max_connections})
  """
  @type config :: [
          {:host, String.t()}
          | {:scheme, String.t()}
          | {:port, :inet.port_number()}
          | {:local_port, :inet.port_number()}
          | {:max_connections, 1..100}
          | {:set_webhook, boolean()}
        ]
  @spec start_link([{:config, config()} | {:bots, [Types.bot_spec()]}]) :: Supervisor.on_start()
  def start_link(opts) do
    config = Keyword.fetch!(opts, :config)
    bot_specs = Keyword.fetch!(opts, :bots)
    Supervisor.start_link(__MODULE__, {config, bot_specs}, name: __MODULE__)
  end

  @impl Supervisor
  def init({config, bot_specs}) do
    config = Keyword.merge(@default_config, config)
    scheme = Keyword.fetch!(config, :scheme)
    host = Keyword.fetch!(config, :host)
    port = Keyword.fetch!(config, :port)
    max_connections = Keyword.fetch!(config, :max_connections)
    set_webhook = Keyword.fetch!(config, :set_webhook)

    bot_routing_map =
      bot_specs
      |> Map.new(fn {bot_behaviour_mod, opts} ->
        token = Keyword.fetch!(opts, :token)
        {token, bot_behaviour_mod}
      end)

    :persistent_term.put({__MODULE__, :bot_routing_map}, bot_routing_map)

    bot_specs
    |> Enum.each(fn {bot_behaviour_mod, opts} ->
      token = Keyword.fetch!(opts, :token)
      url = %URI{scheme: scheme, host: host, path: "/#{token}", port: port} |> to_string()

      Logger.info("Running in webhook mode #{url}", bot: bot_behaviour_mod, token: token)

      if set_webhook do
        # coveralls-ignore-start
        set_webhook(token, url, max_connections)
        # coveralls-ignore-stop
      else
        Logger.info("Skipped setWebhook as requested via config.set_webhook", bot: bot_behaviour_mod, token: token)
      end
    end)

    webserver_specs =
      case Application.get_env(:telegram, :webserver, Telegram.WebServer.Bandit) do
        # coveralls-ignore-start
        nil ->
          []

        # coveralls-ignore-stop

        webserver ->
          local_port = Keyword.fetch!(config, :local_port)
          [webserver.child_spec(local_port)]
      end

    children = bot_specs ++ webserver_specs

    Supervisor.init(children, strategy: :one_for_one)
  end

  # coveralls-ignore-start

  defp set_webhook(token, url, max_connections) do
    opts = [url: url, max_connections: max_connections]
    {:ok, _} = retry(fn -> Telegram.Api.request(token, "setWebhook", opts) end)
  end

  # coveralls-ignore-stop

  @doc """
  This function can be used to process an incoming webhook request
  if you opted to serve the webhook in your app via a `Plug` router.

  ```elixir
  defmodule App.Router do
    use Plug.Router

    # ... my app routes ...

    post "/__telegram_webhook__/:token" do
      Telegram.Webhook.post_webhook(conn, token)
    end
  end
  ```
  """
  @spec post_webhook(Plug.Conn.t(), Types.token()) :: Plug.Conn.t()
  def post_webhook(%Plug.Conn{} = conn, token) do
    bot_routing_map = :persistent_term.get({Telegram.Webhook, :bot_routing_map})

    with {:read_update, {:ok, update, conn}} <- {:read_update, read_update(conn)},
         {:routing, {:ok, bot_dispatch_behaviour}} <- {:routing, Map.fetch(bot_routing_map, token)} do
      Logger.debug("received update: #{inspect(update)}", bot: inspect(bot_dispatch_behaviour))
      bot_dispatch_behaviour.dispatch_update(update, token)
      Plug.Conn.send_resp(conn, :ok, "")
    else
      # coveralls-ignore-start

      {:read_update, _} ->
        Plug.Conn.send_resp(conn, :bad_request, "")

      {:routing, :error} ->
        Plug.Conn.send_resp(conn, :not_found, "")

        # coveralls-ignore-stop
    end
  end

  # coveralls-ignore-start

  defp read_update(%Plug.Conn{body_params: %Plug.Conn.Unfetched{}} = conn) do
    with {:read, {:ok, body, conn}} <- {:read, Plug.Conn.read_body(conn)},
         {:decode, {:ok, update}} <- {:decode, Jason.decode(body)} do
      {:ok, update, conn}
    else
      {:read, error} ->
        {:error, error}

      {:decode, error} ->
        error
    end
  end

  # coveralls-ignore-stop

  defp read_update(%Plug.Conn{body_params: %{}} = conn) do
    {:ok, conn.body_params, conn}
  end
end

defmodule Telegram.Webhook.Router do
  @moduledoc false

  require Logger

  use Plug.Router, copy_opts_to_assign: :bot_routing_map

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason
  plug :dispatch

  post "/__telegram_webhook__/:token" do
    Telegram.Webhook.post_webhook(conn, token)
  end

  # coveralls-ignore-start

  match _ do
    Plug.Conn.send_resp(conn, :not_found, "")
  end

  # coveralls-ignore-stop
end
