defmodule Test.Telegram.Bot.Sync do
  use ExUnit.Case, async: false
  import Test.Utils.{Const, Mock}

  setup [:start_tesla_mock, :start_test_bot]

  test "basic flow" do
    url_get_updates = tg_url(tg_token(), "getUpdates")
    url_test_response = tg_url(tg_token(), "testResponse")

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
               end
             )
  end

  defp start_tesla_mock(_context) do
    tesla_mock_global_async(self())
    :ok
  end

  defp start_test_bot(_context) do
    token = tg_token()
    options = [purge: false]

    start_supervised!({Telegram.Bot.Sync.Supervisor, {Test.Bot, token, options}})

    :ok
  end
end
