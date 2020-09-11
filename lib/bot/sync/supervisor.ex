defmodule Telegram.Bot.Sync.Supervisor do
  @moduledoc """
  Bot Supervisor - Synchronous update dispatching

  Start the `Telegram.Bot.Poller` loop dispatching updates synchronously
  It means the Bot `handle_update` function is called in the `Telegram.Bot.Poller` process sequentially.
  """

  use Supervisor

  @type option :: Telegram.Bot.Poller.options()

  @spec start_link({module(), Telegram.Client.token(), [option()]}) :: Supervisor.on_start()
  def start_link({bot_module, token, options}) do
    Supervisor.start_link(__MODULE__, {bot_module, token, options}, name: name(bot_module))
  end

  @spec name(module()) :: atom()
  def name(bot_module) do
    String.to_atom("#{__MODULE__}.#{bot_module}")
  end

  @impl Supervisor
  def init({bot_module, token, options}) do
    handle_update = fn update, token ->
      bot_module.handle_update(update, token)
    end

    Supervisor.init(
      [{Telegram.Bot.Poller, {handle_update, token, options}}],
      strategy: :one_for_one
    )
  end
end
