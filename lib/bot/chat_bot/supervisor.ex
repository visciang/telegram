defmodule Telegram.Bot.ChatBot.Supervisor do
  @moduledoc """
  ChatBot top supervisor.
  """

  use Supervisor
  alias Telegram.Bot.ChatBot

  @type option :: Telegram.Bot.Poller.options() | {:max_bot_concurrency, non_neg_integer()}

  @spec start_link({module(), Telegram.Client.token(), [option()]}) :: Supervisor.on_start()
  def start_link({bot_module, token, options}) do
    Supervisor.start_link(__MODULE__, {bot_module, token, options}, name: name(bot_module))
  end

  @spec name(module()) :: atom()
  def name(bot_module) do
    String.to_atom("#{__MODULE__}.#{bot_module}")
  end

  @impl Supervisor
  def init({bot_module, token, options}) do
    {max_bot_concurrency, options} = Keyword.pop(options, :max_bot_concurrency, :infinity)

    handle_update = &ChatBot.Chat.Supervisor.handle_update(bot_module, &1, &2)
    poller = {Telegram.Bot.Poller, {handle_update, token, options}}
    chat_supervisor = {ChatBot.Chat.Supervisor, {bot_module, max_bot_concurrency}}

    children = [chat_supervisor, poller]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
