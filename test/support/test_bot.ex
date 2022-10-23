defmodule Test.Bot do
  @moduledoc false

  use Telegram.Bot

  @impl Telegram.Bot
  def handle_update(_update, token) do
    Telegram.Api.request(token, "testResponse")
  end
end
