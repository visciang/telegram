defmodule Test.Telegram.Bot.Async do
  use ExUnit.Case, async: false
  import Test.Utils.{Const, Mock}

  setup_all do
    Test.Utils.Mock.tesla_mock_global_async()
    :ok
  end

  setup [:setup_test_bot]

  test "basic flow" do
    url_delete_webhook = tg_url(tg_token(), "deleteWebhook")
    url_get_updates = tg_url(tg_token(), "getUpdates")
    url_test_response = tg_url(tg_token(), "testResponse")

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_delete_webhook},
               fn _ ->
                 response = %{"ok" => true, "result" => true}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_get_updates},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["offset"] == nil

                 result = [
                   %{
                     "update_id" => 1,
                     "message" => %{"text" => "/command"}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_test_response},
               fn _request ->
                 response = %{"ok" => true, "result" => "ok"}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )
  end

  defp setup_test_bot(_context) do
    options = [token: tg_token(), max_bot_concurrency: 1]
    start_supervised!({Test.Bot, options})

    :ok
  end
end
