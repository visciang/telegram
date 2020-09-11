defmodule Test.Telegram.ChatBot do
  use ExUnit.Case, async: false

  import Test.Utils.{Const, Mock}

  defp start_tesla_mock(_context) do
    tesla_mock_global_async(self())
    :ok
  end

  defp start_test_bot(_context) do
    token = tg_token()
    purge = false

    start_supervised!({Telegram.Bot.ChatBot.Supervisor, {Test.ChatBot, token, purge: purge}})

    :ok
  end

  describe "chat_bot" do
    setup [:start_tesla_mock, :start_test_bot]

    test "basic flow" do
      :ok
      url_get_updates = tg_url(tg_token(), "getUpdates")
      url_test_response = tg_url(tg_token(), "testResponse")
      chat_id = "chat_id_1234"

      1..3
      |> Enum.each(fn idx ->
        assert :ok ==
                 tesla_mock_expect_request(
                   %{method: :post, url: ^url_get_updates},
                   fn _ ->
                     result = [
                       %{
                         "update_id" => idx,
                         "message" => %{"text" => "/count", "chat" => %{"id" => chat_id}}
                       }
                     ]

                     response = %{"ok" => true, "result" => result}
                     Tesla.Mock.json(response, status: 200)
                   end
                 )

        assert :ok ==
                 tesla_mock_expect_request(
                   %{method: :post, url: ^url_test_response},
                   fn %{body: body} ->
                     body = Jason.decode!(body)
                     assert body["chat_id"] == chat_id
                     assert body["text"] == "#{idx}"

                     response = %{"ok" => true, "result" => []}
                     Tesla.Mock.json(response, status: 200)
                   end,
                   false
                 )
      end)
    end
  end
end
