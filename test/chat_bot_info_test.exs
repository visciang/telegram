defmodule Test.Telegram.ChatBotInfo do
  use ExUnit.Case, async: false

  alias Test.Webhook
  import Test.Utils.{Const, Mock}

  setup_all {Test.Utils.Mock, :setup_tesla_mock_global_async}
  setup :setup_test_bot

  test "info message" do
    url_test_response = tg_url(tg_token(), "testResponse")

    chat_id = "chat_id"

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "message" => %{"text" => "/command", "chat" => %{"id" => chat_id}}
             })

    assert :ok ==
             tesla_mock_assert_request(
               %{method: :post, url: ^url_test_response},
               fn %{body: _body} ->
                 response = %{"ok" => true, "result" => "ok"}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )

    {:ok, pid} = Telegram.ChatBot.lookup(tg_token(), chat_id)

    send(pid, {:test, self()})

    assert_receive :ok
  end

  defp setup_test_bot(_context) do
    config = [set_webhook: false, host: "host.com"]
    bots = [{Test.ChatBotInfo, [token: tg_token(), max_bot_concurrency: 1]}]
    start_supervised!({Telegram.Webhook, config: config, bots: bots})

    :ok
  end
end
