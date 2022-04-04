defmodule Telegram.ChatBot do
  @moduledoc """
  Telegram Chat Bot behaviour.

  The difference with `Telegram.Bot` behaviour is that the `Telegram.ChatBot` is "statefull" per chat_id,
  (see `chat_state` argument)
  """

  @type chat :: map()
  @type chat_state :: any()

  @doc """
  Invoked once when the chat starts.
  Return the initial chat_state.
  """
  @callback init(chat :: chat()) :: {:ok, chat_state()}

  @doc """
  Receives the telegram update event and the "current" chat_state.
  Return the "updated" chat_state.
  """
  @callback handle_update(
              update :: Telegram.Types.update(),
              token :: Telegram.Types.token(),
              chat_state :: chat_state()
            ) :: {:ok, next_chat_state :: chat_state()} | {:stop, next_chat_state :: chat_state()}
end
