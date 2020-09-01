defmodule Telegram.Bot.Supervisor.Sync do
  use Supervisor

  @type option :: Telegram.Bot.Poller.options()

  @spec start_link({module(), Telegram.Client.token(), [option()]}) :: Supervisor.on_start()
  def start_link({bot_module, token, options}) do
    Supervisor.start_link(__MODULE__, {bot_module, token, options}, name: String.to_atom("#{__MODULE__}.#{bot_module}"))
  end

  @impl true
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
