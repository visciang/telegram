defmodule Test.Telegram.ChatBotGetChat do
  use ExUnit.Case, async: false

  alias Test.Webhook
  import Test.Utils.{Const, Mock}

  setup_all {Test.Utils.Mock, :setup_tesla_mock_global_async}
  setup :setup_test_bot

  test "updates" do
    url_test_response = tg_url(tg_token(), "testResponse")
    chat_id = "chat_id_1234"

    1..3
    |> Enum.each(fn idx ->
      assert {:ok, _} =
               Webhook.update(tg_token(), %{
                 "update_id" => idx,
                 "message" => %{"text" => "/count", "chat" => %{"id" => chat_id}}
               })

      assert :ok ==
               tesla_mock_assert_request(
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

  test "inline query" do
    url_test_response = tg_url(tg_token(), "testResponse")
    query_id_base = "chat_id_1234"

    1..3
    |> Enum.each(fn idx ->
      assert {:ok, _} =
               Webhook.update(tg_token(), %{
                 "update_id" => idx,
                 "inline_query" => %{
                   "id" => "#{query_id_base}_#{idx}",
                   "query" => "some query",
                   "chat_type" => "private",
                   "offset" => "",
                   "from" => %{"id" => "user_id"}
                 }
               })

      assert :ok ==
               tesla_mock_assert_request(
                 %{method: :post, url: ^url_test_response},
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["query_id"] == "#{query_id_base}_#{idx}"
                   assert body["query"] == "some query"
                   assert body["text"] == "1"

                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end,
                 false
               )
    end)
  end

  test "received update out of a chat - ie: chat_id not present" do
    url_test_response = tg_url(tg_token(), "testResponse")

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "update_without_chat_if" => %{}
             })

    assert :ok ==
             tesla_mock_refute_request(%{method: :post, url: ^url_test_response})
  end

  defp setup_test_bot(_context) do
    config = [set_webhook: false, host: "host.com"]
    bots = [{Test.ChatBotGetChat, [token: tg_token(), max_bot_concurrency: 1]}]
    start_supervised!({Telegram.Webhook, config: config, bots: bots})

    :ok
  end
end
