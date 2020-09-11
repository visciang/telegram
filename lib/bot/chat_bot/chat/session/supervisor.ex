defmodule Telegram.Bot.ChatBot.Chat.Session.Supervisor do
  @moduledoc """
  ChatBot chat session supervisor.
  """

  use DynamicSupervisor
  alias Telegram.Bot.ChatBot

  @spec start_link({module(), non_neg_integer()}) :: Supervisor.on_start()
  def start_link({bot_module, max_bot_concurrency}) do
    DynamicSupervisor.start_link(__MODULE__, {max_bot_concurrency}, name: name(bot_module))
  end

  @spec name(module()) :: atom()
  def name(bot_module) do
    String.to_atom("#{__MODULE__}.#{bot_module}")
  end

  @spec start_child(module(), String.t()) :: DynamicSupervisor.on_start_child()
  def start_child(bot_module, chat_id) do
    DynamicSupervisor.start_child(name(bot_module), {ChatBot.Chat.Session.Server, {bot_module, chat_id}})
  end

  @impl DynamicSupervisor
  def init({max_bot_concurrency}) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: max_bot_concurrency)
  end
end
