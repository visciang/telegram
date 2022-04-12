defmodule Telegram.Bot do
  @moduledoc ~S"""
  Telegram Bot behaviour.

  ## Example

      defmodule HelloBot do
        use Telegram.Bot

        @impl Telegram.Bot
        def handle_update(
          %{"message" => %{"text" => "/hello", "chat" => %{"id" => chat_id, "username" => username}, "message_id" => message_id}},
          token
        ) do
          Telegram.Api.request(token, "sendMessage",
            chat_id: chat_id,
            reply_to_message_id: message_id,
            text: "Hello #{username}!"
          )
        end

        def handle_update(_update, _token) do
          # ignore unknown updates

          :ok
        end
      end
  """

  @doc """
  The function receives the telegram update event.
  """
  @callback handle_update(update :: Telegram.Types.update(), token :: Telegram.Types.token()) :: any()

  @doc false
  defmacro __using__(_use_opts) do
    quote location: :keep do
      @behaviour Telegram.Bot

      def child_spec(token: token, max_bot_concurrency: max_bot_concurrency) do
        opts = [
          bot_behaviour_mod: __MODULE__,
          token: token,
          max_bot_concurrency: max_bot_concurrency
        ]

        Supervisor.child_spec({Telegram.Bot.Async.Supervisor, opts}, id: __MODULE__)
      end
    end
  end
end
