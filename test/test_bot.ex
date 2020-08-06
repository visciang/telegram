defmodule Test.Stateless.Bot do
  @behaviour Telegram.Bot

  def handle_update(_update, token) do
    Telegram.Api.request(token, "testResponse")
  end
end
