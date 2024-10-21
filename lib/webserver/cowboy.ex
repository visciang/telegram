# coveralls-ignore-start

defmodule Telegram.WebServer.Cowboy do
  @moduledoc """
  Cowboy child specification for `Plug` compatible webserver.

  See `Telegram.Webhook`.
  """

  @spec child_spec(:inet.port_number()) :: {module(), term()}
  def child_spec(port) do
    unless Code.ensure_loaded?(Plug.Cowboy) do
      raise """
      Missing :plug_cowboy dependency.

      See Telegram.Webhook documentation.
      """
    end

    {Plug.Cowboy,
     [
       scheme: :http,
       plug: Telegram.Webhook.Router,
       options: [
         port: port
       ]
     ]}
  end
end

# coveralls-ignore-stop
