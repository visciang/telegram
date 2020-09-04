defmodule Telegram.Bot.Supervisor.Async do
  @moduledoc """
  Bot Supervisor - Asynchronous update dispatching

  Start the `Telegram.Bot.Poller` loop dispatching updates asynchronously.
  It means the Bot `handle_update` function is called a Task dinamically spawned,
  so every update is handled in a isolated Task process.
  (this can be controlled/limited with the `max_bot_concurrency` option)
  """

  use Supervisor

  @type option :: Telegram.Bot.Poller.options() | {:max_bot_concurrency, non_neg_integer()}

  @spec start_link({module(), Telegram.Client.token(), [option()]}) :: Supervisor.on_start()
  def start_link({bot_module, token, options}) do
    Supervisor.start_link(__MODULE__, {bot_module, token, options}, name: String.to_atom("#{__MODULE__}.#{bot_module}"))
  end

  @impl Supervisor
  def init({bot_module, token, options}) do
    {max_bot_concurrency, options} = Keyword.pop(options, :max_bot_concurrency, :infinity)
    workers_supervisor_name = String.to_atom("Telegram.Bot.Workers.Supervisor.#{bot_module}")

    bot_supervisor = {Task.Supervisor, name: workers_supervisor_name, max_children: max_bot_concurrency}

    handle_update = fn update, token ->
      Task.Supervisor.start_child(
        workers_supervisor_name,
        bot_module,
        :handle_update,
        [update, token]
      )
    end

    bot_poller = {Telegram.Bot.Poller, {handle_update, token, options}}

    children = [bot_supervisor, bot_poller]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
