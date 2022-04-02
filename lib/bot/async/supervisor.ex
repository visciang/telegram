defmodule Telegram.Bot.Async.Supervisor do
  @moduledoc """
  Bot Supervisor - Asynchronous update dispatching

  Start the `Telegram.Bot.Poller` loop dispatching updates asynchronously.
  It means the Bot `handle_update` function is called a Task dinamically spawned,
  so every update is handled in a isolated Task process.
  (this can be controlled/limited with the `max_bot_concurrency` option)
  """

  use Supervisor
  alias Telegram.Bot.{Poller, Utils}
  alias Telegram.Types

  @type option :: Poller.options() | {:max_bot_concurrency, Types.max_bot_concurrency()}

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
    {max_bot_concurrency, options} = Keyword.pop(options, :max_bot_concurrency, :infinity)

    supervisor_name = String.to_atom("#{__MODULE__}.Task.Supervisor.#{bot_behaviour}")
    supervisor = {Task.Supervisor, name: supervisor_name, max_children: max_bot_concurrency}

    handle_update = fn update, token ->
      Task.Supervisor.start_child(
        supervisor_name,
        bot_behaviour,
        :handle_update,
        [update, token]
      )
    end

    poller = {Poller, {handle_update, token, options}}

    children = [supervisor, poller]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
