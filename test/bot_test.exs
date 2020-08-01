defmodule Test.Telegram.Bot do
  use ExUnit.Case, async: false
  require Test.Utils, as: Utils

  @tester_username "tester"

  defp start_tesla_mock(_context) do
    Utils.tesla_mock_global_async(self())
    :ok
  end

  defp start_test_bot(_context) do
    token = Test.Utils.tg_token()
    purge = false
    whitelist = [@tester_username]

    start_supervised!({Telegram.Bot.Supervisor, {Test.TestBot, token, purge: purge, whitelist: whitelist}})

    :ok
  end

  defp start_purge_bot(_context) do
    token = Test.Utils.tg_token()
    purge = true
    whitelist = [@tester_username]

    start_supervised!({Telegram.Bot.Supervisor, {Test.TestBot, token, purge: purge, whitelist: whitelist}})

    :ok
  end

  defp expect_get_me(_context) do
    assert :ok ==
             Utils.tesla_mock_expect_request(
               %{method: Utils.http_method(), url: Utils.tg_url("getMe")},
               fn _request ->
                 response = %{"ok" => true, "result" => %{}}
                 Tesla.Mock.json(response, status: 200)
               end
             )

    :ok
  end

  describe "getUpdates" do
    setup [:start_tesla_mock, :start_test_bot, :expect_get_me]

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
                       "message" => %{"text" => "/command", "from" => %{"username" => @tester_username}}
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
                 end
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
                 end
               )
    end

    test "unauthorized user" do
      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates")
                 },
                 fn %{body: body} ->
                   request = Jason.decode!(body)
                   assert request["offset"] == nil

                   result = [
                     %{
                       "update_id" => 1,
                       "message" => %{
                         "text" => "unauth",
                         "from" => %{"username" => "unauth_user"}
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
                   request = Jason.decode!(body)
                   assert request["offset"] == 2

                   response = %{"ok" => true, "result" => []}
                   Tesla.Mock.json(response, status: 200)
                 end
               )
    end
  end

  describe "bootstrap" do
    setup [:start_tesla_mock, :start_test_bot]

    test "Telegram.Bot bootstrap getMe retries" do
      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getMe")
                 },
                 fn _request ->
                   response = %{"ok" => false, "description" => "500"}
                   Tesla.Mock.json(response, status: 500)
                 end
               )

      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getMe")
                 },
                 fn _request ->
                   response = %{"ok" => true, "result" => %{}}
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
                       "message" => %{"text" => "/command", "from" => %{"username" => @tester_username}}
                     }
                   ]

                   response = %{"ok" => true, "result" => result}
                   Tesla.Mock.json(response, status: 200)
                 end
               )
    end
  end

  describe "purge" do
    setup [:start_tesla_mock, :start_purge_bot, :expect_get_me]

    test "Telegram.Bot purge old messages" do
      assert :ok ==
               Utils.tesla_mock_expect_request(
                 %{
                   method: Utils.http_method(),
                   url: Utils.tg_url("getUpdates"),
                   body: body
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
                         "date" => old,
                         "from" => %{"username" => @tester_username}
                       }
                     },
                     %{
                       "update_id" => 2,
                       "message" => %{
                         "text" => "OLD",
                         "date" => old,
                         "from" => %{"username" => @tester_username}
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
                   url: Utils.tg_url("getUpdates"),
                   body: body
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
                         "date" => old,
                         "from" => %{"username" => @tester_username}
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
                 end
               )
    end
  end
end
