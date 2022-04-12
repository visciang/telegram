defmodule Telegram.Bot.ChatBot.Supervisor do
  @moduledoc """
  ChatBot top supervisor.
  """

  use Supervisor
  alias Telegram.Bot.{ChatBot.Chat, Poller, Utils}
  alias Telegram.Bot.ChatBot.Chat.Session
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
  def init(bot_behaviour_mod: bot_behaviour_mod, token: token, max_bot_concurrency: max_bot_concurrency) do
    handle_update = fn update, token ->
      Session.Server.handle_update(bot_behaviour_mod, update, token)
    end

    children = [
      {Chat.Supervisor, {bot_behaviour_mod, max_bot_concurrency}},
      {Poller, {handle_update, token}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
