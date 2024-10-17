defmodule Test.Telegram.ChatBot do
  use ExUnit.Case, async: false

  alias Test.Webhook
  import Test.Utils.{Const, Mock}

  setup_all do
    Test.Utils.Mock.tesla_mock_global_async()
    :ok
  end

  setup [:setup_test_bot]

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

  test "inline query" do
    url_test_response = tg_url(tg_token(), "testResponse")

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "inline_query" => %{
                 "id" => "chat_id_1234",
                 "query" => "some query",
                 "chat_type" => "private",
                 "offset" => "",
                 "from" => %{"id" => "user_id"}
               }
             })

    assert :ok ==
             tesla_mock_refute_request(%{method: :post, url: ^url_test_response})
  end

  test "resume" do
    url_test_response = tg_url(tg_token(), "testResponse")
    chat_id = "chat_id_1234"

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "message" => %{"text" => "/count", "chat" => %{"id" => chat_id}}
             })

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_test_response},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["chat_id"] == chat_id
                 assert body["text"] == "1"

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )

    {:ok, chatbot_server} = Telegram.ChatBot.lookup(tg_token(), chat_id)

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 4,
               "message" => %{"text" => "/stop", "chat" => %{"id" => chat_id}}
             })

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_test_response},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["chat_id"] == chat_id
                 assert body["text"] == "Bye!"

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )

    ref = Process.monitor(chatbot_server)
    assert_receive {:DOWN, ^ref, :process, _, _}

    assert :ok = Test.ChatBot.resume(tg_token(), chat_id, {self(), 50})

    assert_receive :resume

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "message" => %{"text" => "/count", "chat" => %{"id" => chat_id}}
             })

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_test_response},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["chat_id"] == chat_id
                 assert body["text"] == "51"

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )
  end

  test "max_bot_concurrency overflow" do
    url_test_response = tg_url(tg_token(), "testResponse")

    chat_id = "ONE"

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 1,
               "message" => %{"text" => "/count", "chat" => %{"id" => chat_id}}
             })

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_test_response},
               fn %{body: body} ->
                 body = Jason.decode!(body)
                 assert body["chat_id"] == chat_id
                 assert body["text"] == "1"

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )

    chat_id = "TWO"

    assert {:ok, _} =
             Webhook.update(tg_token(), %{
               "update_id" => 2,
               "message" => %{"text" => "/count", "chat" => %{"id" => chat_id}}
             })

    assert :ok ==
             tesla_mock_refute_request(%{method: :post, url: ^url_test_response})
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
    bots = [{Test.ChatBot, [token: tg_token(), max_bot_concurrency: 1]}]
    start_supervised!({Telegram.Webhook, config: config, bots: bots})

    :ok
  end
end
