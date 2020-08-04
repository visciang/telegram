defmodule Test.Telegram.Bot.Utils do
  use ExUnit.Case, async: true

  test "get_from_username" do
    assert nil == Telegram.Bot.Utils.get_from_username(%{})

    assert "test_username" ==
             Telegram.Bot.Utils.get_from_username(%{"message" => %{"from" => %{"username" => "test_username"}}})
  end

  test "get_sent_date" do
    assert nil == Telegram.Bot.Utils.get_sent_date(%{})

    datetime = ~U[2015-05-25 13:26:08Z]

    assert datetime ==
             Telegram.Bot.Utils.get_sent_date(%{"message" => %{"date" => DateTime.to_unix(datetime, :second)}})
  end
end
