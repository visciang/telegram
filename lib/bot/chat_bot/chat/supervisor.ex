defmodule Telegram.Bot.ChatBot.Chat.Supervisor do
  @moduledoc """
  ChatBot chat supervisor.
  """

  use Supervisor
  alias Telegram.Bot.{ChatBot.Chat, Utils}
  alias Telegram.Types

  @spec start_link({module(), Types.max_bot_concurrency()}) :: Supervisor.on_start()
  def start_link({chatbot_behaviour, max_bot_concurrency}) do
    Supervisor.start_link(
      __MODULE__,
      {chatbot_behaviour, max_bot_concurrency},
      name: Utils.name(__MODULE__, chatbot_behaviour)
    )
  end

  @impl Supervisor
  def init({chatbot_behaviour, max_bot_concurrency}) do
    registry = {Chat.Registry, {chatbot_behaviour}}
    session_supervisor = {Chat.Session.Supervisor, {chatbot_behaviour, max_bot_concurrency}}

    children = [registry, session_supervisor]
    Supervisor.init(children, strategy: :one_for_all)
  end
end
