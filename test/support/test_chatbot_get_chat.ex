defmodule Test.ChatBotGetChat do
  @moduledoc false

  use Telegram.ChatBot

  @impl Telegram.ChatBot
  def get_chat("inline_query", %{"id" => _chat_id} = chat) do
    {:transient, chat}
  end
  def get_chat(_, %{"message" => %{"chat" => %{"id" => _} = chat}}) do
    {:ok, chat}
  end
  def get_chat(_, %{"chat" => %{"id" => _} = chat}) do
    {:ok, chat}
  end
  def get_chat(_, _) do
    nil
  end

  @impl Telegram.ChatBot
  def init(_chat) do
    count_state = 0
    {:ok, count_state}
  end

  @impl Telegram.ChatBot
  def handle_resume({test_pid, state}) do
    send(test_pid, :resume)
    {:ok, state}
  end

  @impl Telegram.ChatBot
  def handle_update(%{"inline_query" => %{"id" => query_id, "query" => query}}, token, count_state) do
    count_state = count_state + 1

    Telegram.Api.request(token, "testResponse",
      query_id: query_id,
      query: query,
      text: "#{count_state}"
    )

    {:ok, count_state}
  end

  @impl Telegram.ChatBot
  def handle_update(%{"message" => %{"text" => "/count", "chat" => %{"id" => chat_id}}}, token, count_state) do
    count_state = count_state + 1

    Telegram.Api.request(token, "testResponse",
      chat_id: chat_id,
      text: "#{count_state}"
    )

    {:ok, count_state}
  end

  @impl Telegram.ChatBot
  def handle_update(%{"message" => %{"text" => "/stop", "chat" => %{"id" => chat_id}}}, token, count_state) do
    Telegram.Api.request(token, "testResponse",
      chat_id: chat_id,
      text: "Bye!"
    )

    {:stop, count_state}
  end
end
