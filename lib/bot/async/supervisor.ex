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

  @type options :: [
          bot_behaviour_mod: module(),
          token: Types.token(),
          max_bot_concurrency: Types.max_bot_concurrency()
        ]

  @spec start_link(options()) :: Supervisor.on_start()
  def start_link(opts) do
    bot_behaviour_mod = Keyword.fetch!(opts, :bot_behaviour_mod)
    Supervisor.start_link(__MODULE__, opts, name: Utils.name(__MODULE__, bot_behaviour_mod))
  end

  @impl Supervisor
  def init(opts) do
    bot_behaviour_mod = Keyword.fetch!(opts, :bot_behaviour_mod)
    token = Keyword.fetch!(opts, :token)
    max_bot_concurrency = Keyword.get(opts, :max_bot_concurrency, :infinity)
    supervisor_name = Utils.name(__MODULE__.Task.Supervisor, bot_behaviour_mod)

    handle_update = fn update, token ->
      Task.Supervisor.start_child(
        supervisor_name,
        bot_behaviour_mod,
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
