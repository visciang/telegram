# TOKEN="..." mix run example/example_stateless.exs

defmodule SleepBot do
  @behaviour Telegram.Bot

  @impl true
  def handle_update(
        %{"message" => %{"text" => "/sleep" <> seconds_arg, "chat" => %{"id" => chat_id}, "message_id" => message_id}},
        token
      ) do
    seconds = seconds_arg |> parse_seconds_arg()
    Command.sleep(token, chat_id, message_id, seconds)
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
  require Logger

  def sleep(token, chat_id, message_id, seconds) do
    Telegram.Api.request(token, "sendMessage",
      chat_id: chat_id,
      reply_to_message_id: message_id,
      text: "Sleeping '#{seconds}'s"
    )

    Process.sleep(seconds * 1_000)

    Telegram.Api.request(token, "sendMessage",
      chat_id: chat_id,
      reply_to_message_id: message_id,
      text: "Awake!"
    )
  end

  def unknown(token, update) do
    unknown_message = "Unknown message:\n\n```\n#{inspect(update, pretty: true)}\n```"

    case update do
      %{"message" => %{"message_id" => message_id, "chat" => %{"id" => chat_id}}} ->
        Telegram.Api.request(token, "sendMessage",
          chat_id: chat_id,
          reply_to_message_id: message_id,
          parse_mode: "MarkdownV2",
          text: unknown_message
        )

      _ ->
        Logger.debug(unknown_message)
    end
  end
end

token = System.get_env("TOKEN")

if token == nil do
  IO.puts("Please provide a TOKEN environment variable")
else
  options = [
    purge: true,
    max_bot_concurrency: 1_000
  ]

  Telegram.Bot.Supervisor.Async.start_link({SleepBot, token, options})
  Process.sleep(:infinity)
end
