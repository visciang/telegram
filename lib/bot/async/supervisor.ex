defmodule Telegram.Bot.Async.Supervisor do
  @moduledoc """
  Bot Supervisor - Asynchronous update dispatching

  The Bot `c:Telegram.Bot.handle_update/2` function is called a dynamically spawned Task,
  so every update is handled by an isolated Task process.
  (this can be controlled/limited with the `max_bot_concurrency` option)
  """

  use Supervisor
  alias Telegram.Bot.{Poller, Utils}
  alias Telegram.Types

  @type option :: {:max_bot_concurrency, Types.max_bot_concurrency()}

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
    max_bot_concurrency = Keyword.get(options, :max_bot_concurrency, :infinity)
    supervisor_name = Utils.name(__MODULE__.Task.Supervisor, bot_behaviour)

    handle_update = fn update, token ->
      Task.Supervisor.start_child(
        supervisor_name,
        bot_behaviour,
        :handle_update,
        [update, token]
      )
    end

    children = [
      {Task.Supervisor, name: supervisor_name, max_children: max_bot_concurrency},
      {Poller, {handle_update, token}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
