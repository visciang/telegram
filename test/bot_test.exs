defmodule Test.Telegram.Bot do
  use ExUnit.Case, async: false
  import Test.Utils.{Const, Mock}

  defp start_tesla_mock(_context) do
    tesla_mock_global_async(self())
    :ok
  end

  defp start_sync_test_bot(_context) do
    token = tg_token()
    purge = false

    start_supervised!({Telegram.Bot.Supervisor.Sync, {Test.Bot, token, purge: purge}})

    :ok
  end

  defp start_purge_bot(_context) do
    token = tg_token()
    purge = true

    start_supervised!({Telegram.Bot.Supervisor.Sync, {Test.Bot, token, purge: purge}})

    :ok
  end

  describe "getUpdates" do
    setup [:start_tesla_mock, :start_sync_test_bot]

    test "basic flow" do
      url_get_updates = tg_url(tg_token(), "getUpdates")
      url_test_response = tg_url(tg_token(), "testResponse")

      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url_get_updates},
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == nil

                   response = %{"ok" => true, "result" => []}
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
                 end
               )

      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url_get_updates},
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == 2

                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end
               )
    end

    test "response error" do
      url = tg_url(tg_token(), "getUpdates")

      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url},
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == nil

                   response = %{"ok" => false, "description" => "AZZ"}
                   Tesla.Mock.json(response, status: 200)
                 end
               )

      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url},
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == nil
                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end
               )
    end
  end

  describe "purge" do
    setup [:start_tesla_mock, :start_purge_bot]

    test "Telegram.Bot purge old messages" do
      url = tg_url(tg_token(), "getUpdates")

      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url},
                 fn %{body: body} ->
                   now = DateTime.utc_now() |> DateTime.to_unix(:second)
                   old = now - 1_000

                   body = Jason.decode!(body)
                   assert body["offset"] == nil

                   result = [
                     %{
                       "update_id" => 1,
                       "message" => %{
                         "text" => "OLD",
                         "date" => old
                       }
                     },
                     %{
                       "update_id" => 2,
                       "message" => %{
                         "text" => "OLD",
                         "date" => old
                       }
                     }
                   ]

                   response = %{"ok" => true, "result" => result}
                   Tesla.Mock.json(response, status: 200)
                 end
               )

      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url},
                 fn %{body: body} ->
                   now = DateTime.utc_now() |> DateTime.to_unix(:second)
                   old = now - 1_000

                   body = Jason.decode!(body)
                   assert body["offset"] == 3

                   result = [
                     %{
                       "update_id" => 3,
                       "message" => %{
                         "text" => "OLD",
                         "date" => old
                       }
                     }
                   ]

                   response = %{"ok" => true, "result" => result}
                   Tesla.Mock.json(response, status: 200)
                 end
               )

      # first not purged update
      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url},
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == 4

                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end
               )
    end
  end
end
