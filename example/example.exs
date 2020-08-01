# TOKEN="..." USERNAME="..." mix run example/example.exs

defmodule DummyBot do
  @behaviour Telegram.Bot

  @impl true
  def handle_update(%{"message" => %{"text" => "/hello", "chat" => chat}}, token) do
    Command.hello(token, chat)
  end

  def handle_update(
        %{"message" => %{"text" => "/sleep" <> seconds_arg, "chat" => chat, "message_id" => message_id}},
        token
      ) do
    seconds = seconds_arg |> parse_seconds_arg()
    Command.sleep(token, chat, message_id, seconds)
  end

  def handle_update(update, token) do
    Command.unknown(token, update)
  end

  defp parse_seconds_arg(arg) do
    default_arg = "1"
    arg = if arg == "", do: default_arg, else: arg
    {seconds, ""} = arg |> String.trim() |> Integer.parse()
    seconds
  end
end

defmodule Command do
  def hello(token, chat) do
    Telegram.Api.request(token, "sendMessage",
      chat_id: chat["id"],
      text: "Hello '#{chat["username"]}'"
    )
  end

  def sleep(token, chat, message_id, seconds) do
    Telegram.Api.request(token, "sendMessage",
      chat_id: chat["id"],
      reply_to_message_id: message_id,
      text: "Sleeping '#{seconds}'s"
    )

    Process.sleep(seconds * 1000)

    Telegram.Api.request(token, "sendMessage",
      chat_id: chat["id"],
      reply_to_message_id: message_id,
      text: "Awake!"
    )
  end

  def unknown(token, update) do
    chat_id = update["message"]["chat"]["id"]
    message_id = update["message"]["message_id"]

    if chat_id do
      Telegram.Api.request(token, "sendMessage",
        chat_id: chat_id,
        reply_to_message_id: message_id,
        parse_mode: "MarkdownV2",
        text: "Unknown message:\n\n```\n#{inspect(update, pretty: true)}\n```"
      )
    end
  end
end

token = System.get_env("TOKEN")

if token == nil do
  IO.puts("Please provide a TOKEN environment variable")
else
  options = [
    purge: true,
    whitelist: nil,
    max_bot_concurrency: 1_000
  ]

  Telegram.Bot.Supervisor.start_link({DummyBot, token, options})
  Process.sleep(:infinity)
end
