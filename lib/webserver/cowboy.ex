# coveralls-ignore-start

defmodule Telegram.WebServer.Cowboy do
  @moduledoc """
  Cowboy child specification for `Plug` compatible webserver.

  See `Telegram.Webhook`.
  """
  alias Telegram.Types

  @spec child_spec(:inet.port_number(), Types.bot_routing()) :: {module(), term()}
  def child_spec(port, bot_routing_map) do
    unless Code.ensure_loaded?(Plug.Cowboy) do
      raise """
      Missing :plug_cowboy dependency.

      See Telegram.Webhook documentation.
      """
    end

    {Plug.Cowboy,
     [
       scheme: :http,
       plug: {Telegram.Webhook.Router, bot_routing_map},
       options: [
         port: port
       ]
     ]}
  end
end

# coveralls-ignore-stop
