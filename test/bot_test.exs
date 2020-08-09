defmodule Test.Telegram.Bot do
  use ExUnit.Case, async: false
  require Test.Utils, as: Utils

  defp start_tesla_mock(_context) do
    Utils.tesla_mock_global_async(self())
    :ok
  end

  defp start_test_bot(_context) do
    token = Test.Utils.tg_token()
    purge = false

    start_supervised!({Telegram.Bot.Supervisor, {Test.Bot, token, purge: purge}})

    :ok
  end

  defp start_purge_bot(_context) do
    token = Test.Utils.tg_token()
    purge = true

    start_supervised!({Telegram.Bot.Supervisor, {Test.Bot, token, purge: purge}})

    :ok
  end

  describe "getUpdates" do
    setup [:start_tesla_mock, :start_test_bot]

    test "no update" do
      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == nil

                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end
               )

      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
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
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("testResponse")
                 },
                 fn _request ->
                   response = %{"ok" => true, "result" => "ok"}
                   Tesla.Mock.json(response, status: 200)
                 end
               )

      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == 2

                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end,
                 true
               )
    end

    test "response error" do
      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == nil

                   response = %{"ok" => false, "description" => "AZZ"}
                   Tesla.Mock.json(response, status: 200)
                 end
               )

      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == nil
                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end,
                 true
               )
    end
  end

  describe "purge" do
    setup [:start_tesla_mock, :start_purge_bot]

    test "Telegram.Bot purge old messages" do
      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
                 fn %{body: body} ->
                   now = DateTime.utc_now() |> DateTime.to_unix(:second)
                   old = now - 1000

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
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
                 fn %{body: body} ->
                   now = DateTime.utc_now() |> DateTime.to_unix(:second)
                   old = now - 1000

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
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
                 fn %{body: body} ->
                   body = Jason.decode!(body)
                   assert body["offset"] == 4

                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end,
                 true
               )
    end
  end
end
