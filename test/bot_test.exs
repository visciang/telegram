defmodule Test.Base do
  import ExUnit.Assertions
  require Test.Utils, as: Utils

  @after_timeout Application.get_env(:telegram, :on_error_retry_quiet_period) * 1000 + 5000

  defmacro test_base(test_name, type, text_field, send_text) do
    quote do
      test unquote(test_name), context do
        Test.Base.do_test(
          context.bot,
          unquote(test_name),
          unquote(type),
          unquote(text_field),
          unquote(send_text)
        )
      end
    end
  end

  def do_test(bot, test_name, type, text_field, send_text) do
    assert :ok ==
             Utils.tesla_mock_expect(fn %{
                                          method: Utils.http_method(),
                                          url: Utils.tg_url("getUpdates")
                                        } ->
               result = [
                 %{
                   "update_id" => 1,
                   type => %{text_field => send_text, "from" => %{"username" => "tester"}}
                 }
               ]

               response = %{"ok" => true, "result" => result}
               Tesla.Mock.json(response, status: 200)
             end)

    body = ~s({"result":"ok #{test_name}"})

    assert :ok ==
             Utils.tesla_mock_expect(fn %{
                                          method: Utils.http_method(),
                                          url: Utils.tg_url("testResult"),
                                          body: ^body
                                        } ->
               %Tesla.Env{status: 200}
             end)

    assert :ok ==
             Utils.tesla_mock_expect(fn %{
                                          method: Utils.http_method(),
                                          url: Utils.tg_url("getUpdates"),
                                          body: body
                                        } ->
               request = Jason.decode!(body)
               assert request["offset"] == 2

               result = [
                 %{
                   "update_id" => 2,
                   "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}
                 }
               ]

               response = %{"ok" => true, "result" => result}
               Tesla.Mock.json(response, status: 200)
             end)

    assert :ok == Test.Base.wait_exit(bot)
  end

  def wait_exit(proc) do
    # confirm last message on halt
    assert :ok ==
             Utils.tesla_mock_expect(fn %{
                                          method: Utils.http_method(),
                                          url: Utils.tg_url("getUpdates"),
                                          body: body
                                        } ->
               request = Jason.decode!(body)
               assert request["timeout"] == 0
               result = []
               response = %{"ok" => true, "result" => result}
               Tesla.Mock.json(response, status: 200)
             end)

    ref = Process.monitor(proc)

    receive do
      {:DOWN, ^ref, :process, _object, :normal} ->
        :ok
    after
      @after_timeout ->
        :error
    end
  end

  def wait_exit_with_ArgumentError(proc) do
    ref = Process.monitor(proc)

    receive do
      {:DOWN, ^ref, :process, _object, {%ArgumentError{}, _}} ->
        :ok
    after
      @after_timeout ->
        :error
    end
  end
end

defmodule Test.Telegram.Bot do
  use ExUnit.Case, async: false
  require Test.Utils, as: Utils
  require Test.Base

  defp start_tesla_mock(_context) do
    Utils.tesla_mock_global_async(self())
    :ok
  end

  defp start_good_bot(_context) do
    {:ok, bot} = Test.GoodBot.start()
    {:ok, [bot: bot]}
  end

  defp start_purge_bot(_context) do
    {:ok, bot} = Test.PurgeBot.start()
    {:ok, [bot: bot]}
  end

  defp expect_get_me(_context) do
    assert :ok ==
             Utils.tesla_mock_expect(fn %{method: Utils.http_method(), url: Utils.tg_url("getMe")} ->
               result = %{"username" => "test_bot"}
               response = %{"ok" => true, "result" => result}
               Tesla.Mock.json(response, status: 200)
             end)

    :ok
  end

  describe "Telegram.Bot.Dsl.command macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test1", "message", "text", "/test1")
    Test.Base.test_base("test2", "message", "text", "/test2b")
    Test.Base.test_base("test3", "message", "text", "/test3 a b")
    Test.Base.test_base("test4", "message", "text", "/test4")
  end

  describe "Telegram.Bot.Dsl.message macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test5", "message", "text", "test5")
  end

  describe "Telegram.Bot.Dsl.edited_message macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test6", "edited_message", "text", "test6")
  end

  describe "Telegram.Bot.Dsl.channel_post macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test7", "channel_post", "text", "test7")
  end

  describe "Telegram.Bot.Dsl.edited_channel_post macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test8", "edited_channel_post", "text", "test8")
  end

  describe "Telegram.Bot.Dsl.callback_query macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test9", "callback_query", "text", "test9")
  end

  describe "Telegram.Bot.Dsl.shipping_query macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test10", "shipping_query", "text", "test10")
  end

  describe "Telegram.Bot.Dsl.pre_checkout_query macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test11", "pre_checkout_query", "text", "test11")
  end

  describe "Telegram.Bot.Dsl.inline_query macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test12", "inline_query", "query", "test12")
  end

  describe "Telegram.Bot.Dsl.chosen_inline_result macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test13", "chosen_inline_result", "query", "test13")
  end

  describe "Telegram.Bot.Dsl.any macros" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]
    Test.Base.test_base("test14", "_any_", "text", "test14")
  end

  describe "getUpdates" do
    setup [:start_tesla_mock, :start_good_bot, :expect_get_me]

    test "no update", context do
      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates")
                                          } ->
                 result = []
                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates")
                                          } ->
                 result = [
                   %{
                     "update_id" => 1,
                     "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok == Test.Base.wait_exit(context.bot)
    end

    test "halt the system", context do
      # mock System.stop
      :meck.new(System, [:passthrough])
      :meck.expect(System, :stop, fn -> nil end)

      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates")
                                          } ->
                 result = [
                   %{
                     "update_id" => 1,
                     "message" => %{"text" => "/system_halt", "from" => %{"username" => "tester"}}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok == Test.Base.wait_exit(context.bot)

      # assert System.stop mock has been called
      assert true == :meck.called(System, :stop, :_, context.bot)
      :meck.unload(System)
    end

    test "response error", context do
      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates")
                                          } ->
                 response = %{"ok" => false, "description" => "AZZ"}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates")
                                          } ->
                 result = [
                   %{
                     "update_id" => 1,
                     "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok == Test.Base.wait_exit(context.bot)
    end

    test "unauthorized user", context do
      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates"),
                                            body: body
                                          } ->
                 request = Jason.decode!(body)
                 assert request["offset"] == nil

                 result = [
                   %{
                     "update_id" => 1,
                     "message" => %{"text" => "unauth", "from" => %{"username" => "unauth_user"}}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates"),
                                            body: body
                                          } ->
                 request = Jason.decode!(body)
                 assert request["offset"] == 2

                 result = [
                   %{
                     "update_id" => 2,
                     "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok == Test.Base.wait_exit(context.bot)
    end
  end

  describe "bootstrap" do
    setup [:start_tesla_mock, :start_good_bot]

    test "Telegram.Bot bootstrap getMe retries", context do
      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getMe")
                                          } ->
                 response = %{"ok" => false, "description" => "500"}
                 Tesla.Mock.json(response, status: 500)
               end)

      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getMe")
                                          } ->
                 result = %{"username" => "test_bot"}
                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates")
                                          } ->
                 result = [
                   %{
                     "update_id" => 1,
                     "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok == Test.Base.wait_exit(context.bot)
    end
  end

  describe "purge" do
    setup [:start_tesla_mock, :start_purge_bot, :expect_get_me]

    test "Telegram.Bot purge old messages", context do
      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates"),
                                            body: body
                                          } ->
                 now = DateTime.utc_now() |> DateTime.to_unix(:second)
                 old = now - 1000

                 request = Jason.decode!(body)
                 assert request["offset"] == nil

                 result = [
                   %{
                     "update_id" => 1,
                     "message" => %{
                       "text" => "OLD",
                       "date" => old,
                       "from" => %{"username" => "tester"}
                     }
                   },
                   %{
                     "update_id" => 2,
                     "message" => %{
                       "text" => "OLD",
                       "date" => old,
                       "from" => %{"username" => "tester"}
                     }
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates"),
                                            body: body
                                          } ->
                 now = DateTime.utc_now() |> DateTime.to_unix(:second)
                 old = now - 1000

                 request = Jason.decode!(body)
                 assert request["offset"] == 3

                 result = [
                   %{
                     "update_id" => 3,
                     "message" => %{
                       "text" => "OLD",
                       "date" => old,
                       "from" => %{"username" => "tester"}
                     }
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      # first not purged update
      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates"),
                                            body: body
                                          } ->
                 now = DateTime.utc_now() |> DateTime.to_unix(:second)

                 request = Jason.decode!(body)
                 assert request["offset"] == 4

                 result = [
                   %{
                     "update_id" => 4,
                     "message" => %{
                       "text" => "/halt",
                       "date" => now,
                       "from" => %{"username" => "tester"}
                     }
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      # first not purged update asked again in the main loop
      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getUpdates"),
                                            body: body
                                          } ->
                 now = DateTime.utc_now() |> DateTime.to_unix(:second)

                 request = Jason.decode!(body)
                 assert request["timeout"] != 0

                 result = [
                   %{
                     "update_id" => 4,
                     "message" => %{
                       "text" => "/halt",
                       "date" => now,
                       "from" => %{"username" => "tester"}
                     }
                   }
                 ]

                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok == Test.Base.wait_exit(context.bot)
    end
  end

  describe "bot spec error" do
    setup [:start_tesla_mock, :start_good_bot]

    test "Telegram.Bot wrong bot username", context do
      assert :ok ==
               Utils.tesla_mock_expect(fn %{
                                            method: Utils.http_method(),
                                            url: Utils.tg_url("getMe")
                                          } ->
                 result = %{"username" => "not_test_bot"}
                 response = %{"ok" => true, "result" => result}
                 Tesla.Mock.json(response, status: 200)
               end)

      assert :ok == Test.Base.wait_exit_with_ArgumentError(context.bot)
    end
  end

  describe "bot def error" do
    test "Bot with bad command list definition" do
      assert_raise ArgumentError, "expected list of commands as strings", fn ->
        Code.require_file("bad_bot.ex", __DIR__)
      end
    end
  end
end
