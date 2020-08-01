defmodule Test.TestBot do
  @behaviour Telegram.Bot

  require Test.Utils

  def handle_update(_update, token) do
    Telegram.Api.request(token, "testResponse")
  end
end
