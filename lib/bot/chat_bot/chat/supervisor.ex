defmodule Telegram.Bot.ChatBot.Chat.Supervisor do
  @moduledoc """
  ChatBot chat supervisor.
  """

  use Supervisor
  alias Telegram.Bot.{ChatBot.Chat, Utils}
  alias Telegram.Types

  @spec start_link({Types.token(), Types.max_bot_concurrency()}) :: Supervisor.on_start()
  def start_link({token, max_bot_concurrency}) do
    Supervisor.start_link(
      __MODULE__,
      {token, max_bot_concurrency},
      name: Utils.name(__MODULE__, token)
    )
  end

  @impl Supervisor
  def init({token, max_bot_concurrency}) do
    registry = {Chat.Registry, {token}}
    session_supervisor = {Chat.Session.Supervisor, {token, max_bot_concurrency}}

    children = [registry, session_supervisor]
    Supervisor.init(children, strategy: :one_for_all)
  end
end
