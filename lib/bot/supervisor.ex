defmodule Telegram.Bot.Supervisor do
  use Supervisor

  @type option :: Telegram.Bot.UpdatesPoller.options() | {:max_bot_concurrency, non_neg_integer()}

  @spec start_link({module(), Telegram.Client.token(), [option()]}) ::
          Supervisor.on_start()
  def start_link({bot_module, token, options}) do
    Supervisor.start_link(__MODULE__, {bot_module, token, options}, name: String.to_atom("#{__MODULE__}.#{bot_module}"))
  end

  @doc false
  @impl true
  def init({bot_module, token, options}) do
    {max_bot_concurrency, options} = Keyword.pop(options, :max_bot_concurrency, :infinity)
    bot_worker_supervisor_name = String.to_atom("Telegram.Bot.Workers.Supervisor.#{bot_module}")

    worker_supervisor = {Task.Supervisor, name: bot_worker_supervisor_name, max_children: max_bot_concurrency}

    dispatcher =
      {Telegram.Bot.UpdatesPoller,
       {
         bot_worker_supervisor_name,
         bot_module,
         token,
         options
       }}

    children = [worker_supervisor, dispatcher]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
