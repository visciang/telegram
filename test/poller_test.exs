defmodule Test.Telegram.Bot.Poller do
  use ExUnit.Case, async: false
  import Test.Utils.{Const, Mock}

  setup_all do
    Test.Utils.Mock.tesla_mock_global_async()
    :ok
  end

  setup _context do
    t_token = tg_token()

    handle_update = fn update, token ->
      assert token == t_token
      assert %{"message" => %{"text" => "/test"}} = update
    end

    start_supervised!({Telegram.Bot.Poller, {handle_update, t_token}})

    :ok
  end

  test "basic flow" do
    url_get_updates = tg_url(tg_token(), "getUpdates")

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
                     "message" => %{"text" => "/test"}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
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
