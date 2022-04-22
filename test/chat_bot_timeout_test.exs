defmodule Test.Telegram.ChatBotTimeout do
  use ExUnit.Case, async: false

  alias Test.Webhook
  import Test.Utils.{Const, Mock}

  setup_all do
    Test.Utils.Mock.tesla_mock_global_async()
    :ok
  end

  setup [:setup_test_bot]

  test "timeout" do
    url_test_response = tg_url(tg_token(), "testResponse")

    chat_id = "chat_id"

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "message" => %{"text" => "/command", "chat" => %{"id" => chat_id}}
             })

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_test_response},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["chat_id"] == chat_id
                 assert body["text"] == "1"

                 response = %{"ok" => true, "result" => "ok"}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )

    # let's wait a bit more that the bot TTL.
    # the next command should hit a new bot instance
    Process.sleep(1_000 + 100)

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "message" => %{"text" => "/command", "chat" => %{"id" => chat_id}}
             })

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_test_response},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["chat_id"] == chat_id

                 # counter not increased
                 assert body["text"] == "1"

                 response = %{"ok" => true, "result" => "ok"}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )
  end

  defp setup_test_bot(_context) do
    config = [
      set_webhook: false,
      host: "host.com"
    ]

    bots = [{Test.ChatBotTimeout, [token: tg_token(), max_bot_concurrency: 1]}]
    start_supervised!({Telegram.Webhook, config: config, bots: bots})

    :ok
  end
end
