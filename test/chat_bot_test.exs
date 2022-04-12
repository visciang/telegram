defmodule Test.Telegram.ChatBot do
  use ExUnit.Case, async: false

  import Test.Utils.{Const, Mock}

  setup_all do
    Test.Utils.Mock.tesla_mock_global_async()
    :ok
  end

  setup [:setup_test_bot]

  test "basic flow" do
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

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_get_updates},
               fn _ ->
                 result = [
                   %{
                     "update_id" => 4,
                     "message" => %{"text" => "/stop", "chat" => %{"id" => chat_id}}
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
                 assert body["text"] == "Bye!"

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )
  end

  test "max_bot_concurrency overflow" do
    url_get_updates = tg_url(tg_token(), "getUpdates")
    url_test_response = tg_url(tg_token(), "testResponse")

    chat_id = "ONE"

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_get_updates},
               fn _ ->
                 result = [
                   %{
                     "update_id" => 1,
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
                 assert body["text"] == "1"

                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end,
               false
             )

    chat_id = "TWO"

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_get_updates},
               fn _ ->
                 result = [
                   %{
                     "update_id" => 2,
                     "message" => %{"text" => "/count", "chat" => %{"id" => chat_id}}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    assert :ok ==
             tesla_mock_refute_request(%{method: :post, url: ^url_test_response})
  end

  test "received update out of a chat - ie: chat_id not present" do
    url_get_updates = tg_url(tg_token(), "getUpdates")
    url_test_response = tg_url(tg_token(), "testResponse")

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_get_updates},
               fn _ ->
                 result = [
                   %{
                     "update_id" => 1,
                     "update_without_chat_if" => %{}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    assert :ok ==
             tesla_mock_refute_request(%{method: :post, url: ^url_test_response})

    assert :ok ==
             tesla_mock_expect_request(
               %{method: :post, url: ^url_get_updates},
               fn _ ->
                 response = %{"ok" => true, "result" => []}
                 Tesla.Mock.json(response, status: 200)
               end
             )
  end

  defp setup_test_bot(_context) do
    options = [token: tg_token(), max_bot_concurrency: 1]
    start_supervised!({Test.ChatBot, options})

    :ok
  end
end
