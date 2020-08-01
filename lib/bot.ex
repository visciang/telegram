defmodule Telegram.Bot do
  @callback handle_update(update :: map(), token :: Telegram.Client.token()) :: any()
end
