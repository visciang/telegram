defmodule Telegram.Bot do
  @moduledoc ~S"""
  Telegram Bot behaviour.

  ## Example

  ```elixir
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
  ```
  """

  alias Telegram.Bot.Utils
  alias Telegram.Types

  @doc """
  The function receives the telegram update event.
  """
  @callback handle_update(update :: Types.update(), token :: Types.token()) :: any()

  @doc false
  defmacro __using__(_use_opts) do
    quote location: :keep do
      require Logger

      @behaviour Telegram.Bot

      @spec child_spec(Types.bot_opts()) :: Supervisor.child_spec()
      def child_spec(token: token, max_bot_concurrency: max_bot_concurrency) do
        supervisor_name = Utils.name(__MODULE__, token)
        Supervisor.child_spec({Task.Supervisor, name: supervisor_name, max_children: max_bot_concurrency}, [])
      end

      @spec dispatch_update(Types.update(), Types.token()) :: :ok
      def dispatch_update(update, token) do
        supervisor_name = Utils.name(__MODULE__, token)

        supervisor_name
        |> Task.Supervisor.start_child(__MODULE__, :handle_update, [update, token])
        |> case do
          {:ok, _server} ->
            :ok

          {:error, :max_children} ->
            Logger.info("Reached max children, update dropped", bot: __MODULE__, token: token)
        end
      end
    end
  end
end
