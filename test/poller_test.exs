defmodule Test.Telegram.Poller do
  use ExUnit.Case, async: false
  import Test.Utils.{Const, Mock}

  defmodule TestBotBehaviour do
    use Telegram.Bot

    @impl Telegram.Bot
    def handle_update(update, _token) do
      assert %{"message" => %{"text" => "/test"}} = update
    end
  end

  setup_all {Test.Utils.Mock, :setup_tesla_mock_global_async}
  setup :setup_test_bot

  test "basic flow" do
    url_get_updates = tg_url(tg_token(), "getUpdates")

    assert_webhook_setup(tg_token())

    assert :ok ==
             tesla_mock_assert_request(
               %{method: :post, url: ^url_get_updates},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["offset"] == nil

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    assert :ok ==
             tesla_mock_assert_request(
               %{method: :post, url: ^url_get_updates},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["offset"] == nil

                 result = [
                   %{
                     "update_id" => 1,
                     "message" => %{"text" => "/test"}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    assert :ok ==
             tesla_mock_assert_request(
               %{method: :post, url: ^url_get_updates},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["offset"] == 2

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end
             )
  end

  test "server application error" do
    url = tg_url(tg_token(), "getUpdates")

    assert_webhook_setup(tg_token())

    assert :ok ==
             tesla_mock_assert_request(
               %{method: :post, url: ^url},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["offset"] == nil

                 # Error response
                 response = %{"ok" => false, "description" => "ERROR"}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    assert_webhook_setup(tg_token())

    assert :ok ==
             tesla_mock_assert_request(
               %{method: :post, url: ^url},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["offset"] == nil

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end
             )
  end

  defp assert_webhook_setup(token) do
    url_get_webhook_info = tg_url(token, "getWebhookInfo")
    url_delete_webhook = tg_url(token, "deleteWebhook")

    assert :ok ==
             tesla_mock_assert_request(
               %{method: :post, url: ^url_get_webhook_info},
               fn _ ->
                 response = %{"ok" => true, "result" => %{"url" => "url"}}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    assert :ok ==
             tesla_mock_assert_request(
               %{method: :post, url: ^url_delete_webhook},
               fn _ ->
                 response = %{"ok" => true, "result" => true}
                 Tesla.Mock.json(response, status: 200)
               end
             )
  end

  defp setup_test_bot(_context) do
    bots = [{TestBotBehaviour, [token: tg_token(), max_bot_concurrency: 1]}]
    start_supervised!({Telegram.Poller, bots: bots})

    :ok
  end
end
