defmodule Test.Telegram.Bot.Utils do
  use ExUnit.Case, async: true
  alias Telegram.Bot.Utils

  test "get_from_username" do
    assert nil == Utils.get_from_username(%{"something" => "else"})

    assert {:ok, "test_username"} ==
             Utils.get_from_username(%{"message" => %{"from" => %{"username" => "test_username"}}})
  end

  test "get_sent_date" do
    assert nil == Utils.get_sent_date(%{"something" => "else"})

    datetime = ~U[2015-05-25 13:26:08Z]
    assert {:ok, datetime} == Utils.get_sent_date(%{"message" => %{"date" => DateTime.to_unix(datetime, :second)}})

    datetime = ~U[2015-05-25 13:26:08Z]

    assert {:ok, datetime} ==
             Utils.get_sent_date(%{"callback_query" => %{"message" => %{"date" => DateTime.to_unix(datetime, :second)}}})
  end
end
