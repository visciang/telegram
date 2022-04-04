defmodule Telegram.Bot.ChatBot.Chat.Session.Supervisor do
  @moduledoc """
  ChatBot chat session supervisor.
  """

  use DynamicSupervisor
  alias Telegram.Bot.{ChatBot.Chat, Utils}
  alias Telegram.{ChatBot, Types}

  @spec start_link({module(), Types.max_bot_concurrency()}) :: Supervisor.on_start()
  def start_link({chatbot_behaviour, max_bot_concurrency}) do
    DynamicSupervisor.start_link(
      __MODULE__,
      {max_bot_concurrency},
      name: Utils.name(__MODULE__, chatbot_behaviour)
    )
  end

  @spec start_child(module(), ChatBot.chat()) :: DynamicSupervisor.on_start_child()
  def start_child(chatbot_behaviour, chat) do
    DynamicSupervisor.start_child(
      Utils.name(__MODULE__, chatbot_behaviour),
      {Chat.Session.Server, {chatbot_behaviour, chat}}
    )
  end

  @impl DynamicSupervisor
  def init({max_bot_concurrency}) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: max_bot_concurrency)
  end
end
