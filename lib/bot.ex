defmodule Telegram.Bot do
  @moduledoc """
  Telegram Bot behaviour.
  """

  @doc """
  The function receives the telegram update event.
  """
  @callback handle_update(update :: Telegram.Types.update(), token :: Telegram.Types.token()) :: any()
end
