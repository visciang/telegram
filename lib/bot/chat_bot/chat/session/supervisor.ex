defmodule Telegram.Bot.ChatBot.Chat.Session.Supervisor do
  @moduledoc false

  use DynamicSupervisor
  alias Telegram.Bot.Utils
  alias Telegram.Types

  @spec start_link({Types.token(), Types.max_bot_concurrency()}) :: Supervisor.on_start()
  def start_link({token, max_bot_concurrency}) do
    DynamicSupervisor.start_link(
      __MODULE__,
      {max_bot_concurrency},
      name: Utils.name(__MODULE__, token)
    )
  end

  @spec start_child({module(), term()}, Types.token()) :: DynamicSupervisor.on_start_child()
  def start_child(child_spec, token) do
    DynamicSupervisor.start_child(Utils.name(__MODULE__, token), child_spec)
  end

  @impl DynamicSupervisor
  def init({max_bot_concurrency}) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: max_bot_concurrency)
  end
end
