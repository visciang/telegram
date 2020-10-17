defmodule Telegram.Bot.Sync.Supervisor do
  @moduledoc """
  Bot Supervisor - Synchronous update dispatching

  Start the `Telegram.Bot.Poller` loop dispatching updates synchronously
  It means the Bot `handle_update` function is called in the `Telegram.Bot.Poller` process sequentially.
  """

  use Supervisor
  alias Telegram.Bot.{Poller, Utils}

  @type option :: Poller.options()

  @spec start_link({module(), Telegram.Types.token(), [option()]}) :: Supervisor.on_start()
  def start_link({bot_behaviour, token, options}) do
    Supervisor.start_link(
      __MODULE__,
      {bot_behaviour, token, options},
      name: Utils.name(__MODULE__, bot_behaviour)
    )
  end

  @impl Supervisor
  def init({bot_behaviour, token, options}) do
    handle_update = fn update, token ->
      bot_behaviour.handle_update(update, token)
    end

    Supervisor.init(
      [{Poller, {handle_update, token, options}}],
      strategy: :one_for_one
    )
  end
end
