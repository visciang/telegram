# coveralls-ignore-start

defmodule Telegram.WebServer.Bandit do
  @moduledoc """
  Bandit child specification for `Plug` compatible webserver.

  See `Telegram.Webhook`.
  """

  @spec child_spec(:inet.port_number()) :: {module(), term()}
  def child_spec(port) do
    unless Code.ensure_loaded?(Bandit) do
      raise """
      Missing :bandit dependency.

      See Telegram.Webhook documentation.
      """
    end

    {Bandit,
     [
       scheme: :http,
       plug: Telegram.Webhook.Router,
       port: port
     ]}
  end
end

# coveralls-ignore-stop
