# TOKEN="..." mix run example/example_chatbot.exs

defmodule CountChatBot do
  @moduledoc false

  @behaviour Telegram.ChatBot

  @impl Telegram.ChatBot
  def init() do
    count_state = 0
    {:ok, count_state}
  end

  @impl Telegram.ChatBot
  def handle_update(%{"message" => %{"chat" => %{"id" => chat_id}}}, token, count_state) do
    count_state = count_state + 1

    Telegram.Api.request(token, "sendMessage",
      chat_id: chat_id,
      text: "Hey! You sent me #{count_state} messages"
    )

    {:ok, count_state}
  end

  def handle_update(_update, _token, count_state) do
    # Unknown update
    {:ok, count_state}
  end
end

token = System.get_env("TOKEN")

if token == nil do
  IO.puts("Please provide a TOKEN environment variable")
else
  options = [
    purge: true
  ]

  Telegram.Bot.ChatBot.Supervisor.start_link({CountChatBot, token, options})
  Process.sleep(:infinity)
end
