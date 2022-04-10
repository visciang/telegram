defmodule Telegram.Bot do
  @moduledoc ~S"""
  Telegram Bot behaviour.

  ## Example

      defmodule HelloBot do
        use Telegram.Bot, async: true

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
  defmacro __using__(use_opts) do
    quote location: :keep do
      @behaviour Telegram.Bot

      def child_spec(init_arg) do
        async = Keyword.get(unquote(use_opts), :async, false)
        {token, init_arg} = Keyword.pop!(init_arg, :token)

        sup =
          if async do
            {Telegram.Bot.Async.Supervisor, {__MODULE__, token, init_arg}}
          else
            {Telegram.Bot.Sync.Supervisor, {__MODULE__, token}}
          end

        Supervisor.child_spec(sup, id: __MODULE__)
      end
    end
  end
end
