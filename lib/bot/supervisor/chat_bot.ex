defmodule Telegram.Bot.Supervisor.ChatBot do
  @moduledoc """
  Bot Supervisor - Asynchronous update dispatching

  Start the `Telegram.Bot.Poller` loop dispatching updates to the provided
  `Telegram.ChatBot` behaviour.
  """

  use Supervisor

  @type option :: Telegram.Bot.Poller.options()

  @spec start_link({module(), Telegram.Client.token(), [option()]}) :: Supervisor.on_start()
  def start_link({bot_module, token, options}) do
    Supervisor.start_link(__MODULE__, {bot_module, token, options}, name: String.to_atom("#{__MODULE__}.#{bot_module}"))
  end

  @impl Supervisor
  def init({bot_module, token, options}) do
    # TODO
  end
end
