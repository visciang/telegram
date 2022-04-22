defmodule Test.Telegram.Webhook do
  use ExUnit.Case, async: false

  alias Test.Webhook
  import Test.Utils.{Const, Mock}

  setup_all do
    Test.Utils.Mock.tesla_mock_global_async()
    :ok
  end

  setup [:setup_test_bot]

  test "basic flow" do
    url_test_response = tg_url(tg_token(), "testResponse")

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "message" => %{"text" => "/command"}
             })

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

  test "update to unknown bot" do
    url_test_response = tg_url(tg_token(), "testResponse")

    assert {:error, {:http_error, 404}} =
             Webhook.update("unknown_bot_token", %{
               "update_id" => 1,
               "message" => %{"text" => "/command"}
             })

    assert :ok ==
             tesla_mock_refute_request(%{method: :post, url: ^url_test_response})
  end

  defp setup_test_bot(_context) do
    config = [set_webhook: false, host: "host.com"]
    bots = [{Test.Bot, [token: tg_token(), max_bot_concurrency: 1]}]
    start_supervised!({Telegram.Webhook, config: config, bots: bots})

    :ok
  end
end
