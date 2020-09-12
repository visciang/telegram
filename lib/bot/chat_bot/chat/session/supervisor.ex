defmodule Telegram.Bot.ChatBot.Chat.Session.Supervisor do
  @moduledoc """
  ChatBot chat session supervisor.
  """

  use DynamicSupervisor
  alias Telegram.Bot.{ChatBot.Chat, Utils}

  @spec start_link({module(), non_neg_integer()}) :: Supervisor.on_start()
  def start_link({chatbot_behaviour, max_bot_concurrency}) do
    DynamicSupervisor.start_link(
      __MODULE__,
      {max_bot_concurrency},
      name: Utils.name(__MODULE__, chatbot_behaviour)
    )
  end

  @spec start_child(module(), String.t()) :: DynamicSupervisor.on_start_child()
  def start_child(chatbot_behaviour, chat_id) do
    DynamicSupervisor.start_child(
      Utils.name(__MODULE__, chatbot_behaviour),
      {Chat.Session.Server, {chatbot_behaviour, chat_id}}
    )
  end

  @impl DynamicSupervisor
  def init({max_bot_concurrency}) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: max_bot_concurrency)
  end
end
