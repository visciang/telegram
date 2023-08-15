defmodule Telegram.WebServer.Bandit do
  @moduledoc """
  Bandit child specification for `Plug` compatible webserver.

  See `Telegram.Webhook`.
  """
  alias Telegram.Types

  @spec child_spec(:inet.port_number(), Types.bot_routing()) :: {module(), term()}
  def child_spec(port, bot_routing_map) do
    unless Code.ensure_loaded?(Bandit) do
      # coveralls-ignore-start

      raise """
      Missing :bandit dependency.

      See Telegram.Webhook documentation.
      """

      # coveralls-ignore-stop
    end

    {Bandit,
     [
       scheme: :http,
       plug: {Telegram.Webhook.Router, bot_routing_map},
       port: port
     ]}
  end
end
