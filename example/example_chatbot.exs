# TOKEN="..." mix run example/example_chatbot.exs

defmodule CountChatBot do
  @moduledoc false

  @behaviour Telegram.ChatBot

  @impl Telegram.ChatBot
  def init() do
    {:ok, 0}
  end

  @impl Telegram.ChatBot
  def handle_update(%{"message" => %{"chat" => %{"id" => chat_id}}}, token, state) do
    Telegram.Api.request(token, "sendMessage",
      chat_id: chat_id,
      text: "Hey! You sent me #{state} messages"
    )

    {:ok, state + 1}
  end

  def handle_update(update, token, state) do
    # Unknown update
    {:ok, state}
  end
end

token = System.get_env("TOKEN")

if token == nil do
  IO.puts("Please provide a TOKEN environment variable")
else
  options = [
    purge: true
  ]

  Telegram.Bot.Supervisor.ChatBot.start_link({CountChatBot, token, options})
  Process.sleep(:infinity)
end
