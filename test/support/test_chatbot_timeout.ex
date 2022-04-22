defmodule Test.ChatBotTimeout do
  @moduledoc false

  use Telegram.ChatBot

  @session_ttl 1_000

  @impl Telegram.ChatBot
  def init(_chat) do
    count_state = 1
    {:ok, count_state, @session_ttl}
  end

  @impl Telegram.ChatBot
  def handle_update(%{"message" => %{"text" => "/command", "chat" => %{"id" => chat_id}}}, token, count_state) do
    Telegram.Api.request(token, "testResponse",
      chat_id: chat_id,
      text: "#{count_state}"
    )

    {:ok, count_state + 1, @session_ttl}
  end
end
