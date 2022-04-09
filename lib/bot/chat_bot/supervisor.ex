defmodule Telegram.Bot.ChatBot.Supervisor do
  @moduledoc """
  ChatBot top supervisor.
  """

  use Supervisor
  alias Telegram.Bot.{ChatBot.Chat, Poller, Utils}
  alias Telegram.Bot.ChatBot.Chat.Session
  alias Telegram.Types

  @type option :: {:max_bot_concurrency, Types.max_bot_concurrency()}

  @spec start_link({module(), Telegram.Types.token(), [option()]}) :: Supervisor.on_start()
  def start_link({chatbot_behaviour, token, options}) do
    Supervisor.start_link(
      __MODULE__,
      {chatbot_behaviour, token, options},
      name: Utils.name(__MODULE__, chatbot_behaviour)
    )
  end

  @impl Supervisor
  def init({chatbot_behaviour, token, options}) do
    max_bot_concurrency = Keyword.get(options, :max_bot_concurrency, :infinity)

    handle_update = &Session.Server.handle_update(chatbot_behaviour, &1, &2)

    children = [
      {Chat.Supervisor, {chatbot_behaviour, max_bot_concurrency}},
      {Poller, {handle_update, token}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
