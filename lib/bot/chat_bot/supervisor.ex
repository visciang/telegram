defmodule Telegram.Bot.ChatBot.Supervisor do
  @moduledoc """
  ChatBot top supervisor.
  """

  use Supervisor
  alias Telegram.Bot.{ChatBot.Chat, Poller, Utils}
  alias Telegram.Bot.ChatBot.Chat.Session

  @type option :: Poller.options() | {:max_bot_concurrency, non_neg_integer()}

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
    {max_bot_concurrency, options} = Keyword.pop(options, :max_bot_concurrency, :infinity)

    handle_update = &Session.Server.handle_update(chatbot_behaviour, &1, &2)
    poller = {Poller, {handle_update, token, options}}
    chat_supervisor = {Chat.Supervisor, {chatbot_behaviour, max_bot_concurrency}}

    children = [chat_supervisor, poller]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
