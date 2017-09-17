defmodule Test.Template do
  defmacro test_base(test_name, type, text_field, send_text) do
    quote do
      test unquote(test_name), %{bypass: bypass} do
        Bypass.expect bypass, Test.Utils.http_method, Test.Utils.tg_path("getUpdates"), fn conn ->
          {:ok, req_body, _} = Plug.Conn.read_body(conn)
          req = Poison.decode!(req_body)

          if Test.HaltSemaphore.halt? do
            assert req["offset"] == 2

            result = [%{"update_id" => 2, "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}}]
            Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
          else
            result = [%{"update_id" => 1, unquote(type) => %{unquote(text_field) => unquote(send_text), "from" => %{"username" => "tester"}}}]
            Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
          end
        end

        Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path("testResult"), fn conn ->
          Test.HaltSemaphore.halt()

          {:ok, req_body, _} = Plug.Conn.read_body(conn)
          assert ~s({"result":"ok #{unquote(test_name)}"}) == req_body
          Test.Utils.put_json_resp(conn, 200, "")
        end

        {:ok, bot} = Test.GoodBot.start_link()
        assert :ok == Test.Utils.wait_exit(bot)
      end
    end
  end
end

defmodule Test.HaltSemaphore do
  use Agent

  def start_link do
    Agent.start_link(fn -> false end, name: __MODULE__)
  end

  def halt? do
    Agent.get(__MODULE__, fn (state) -> state end)
  end

  def halt do
    Agent.update(__MODULE__, fn (_) -> true end)
  end
end

defmodule Test.Telegram.Bot do
  use ExUnit.Case, async: false
  require Test.Template

  setup do
    {:ok, _} = Test.HaltSemaphore.start_link()

    bypass = Bypass.open(port: Test.Utils.tg_port)

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path("getMe"), fn conn ->
      result = %{"username" => "test_bot"}
      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    on_exit fn ->
      Test.Utils.wait_bypass_exit(bypass)
    end

    {:ok, bypass: bypass}
  end

  describe "Telegram.Bot.Dsl.command macros" do
    Test.Template.test_base("test1", "message", "text", "/test1")
    Test.Template.test_base("test2", "message", "text", "/test2b")
    Test.Template.test_base("test3", "message", "text", "/test3 a b")
    Test.Template.test_base("test4", "message", "text", "/test4")
  end

  describe "Telegram.Bot.Dsl.message macros" do
    Test.Template.test_base("test5", "message", "text", "test5")
  end

  describe "Telegram.Bot.Dsl.edited_message macros" do
    Test.Template.test_base("test6", "edited_message", "text", "test6")
  end

  describe "Telegram.Bot.Dsl.channel_post macros" do
    Test.Template.test_base("test7", "channel_post", "text", "test7")
  end

  describe "Telegram.Bot.Dsl.edited_channel_post macros" do
    Test.Template.test_base("test8", "edited_channel_post", "text", "test8")
  end

  describe "Telegram.Bot.Dsl.callback_query macros" do
    Test.Template.test_base("test9", "callback_query", "text", "test9")
  end

  describe "Telegram.Bot.Dsl.shipping_query macros" do
    Test.Template.test_base("test10", "shipping_query", "text", "test10")
  end

  describe "Telegram.Bot.Dsl.pre_checkout_query macros" do
    Test.Template.test_base("test11", "pre_checkout_query", "text", "test11")
  end

  describe "Telegram.Bot.Dsl.inline_query macros" do
    Test.Template.test_base("test12", "inline_query", "query", "test12")
  end

  describe "Telegram.Bot.Dsl.chosen_inline_result macros" do
    Test.Template.test_base("test13", "chosen_inline_result", "query", "test13")
  end

  describe "Telegram.Bot.Dsl.any macros" do
    Test.Template.test_base("test14", "_any_", "text", "test14")
  end

  describe "getUpdates" do
    test "no update", %{bypass: bypass} do
      Bypass.expect bypass, Test.Utils.http_method, Test.Utils.tg_path("getUpdates"), fn conn ->
        if Test.HaltSemaphore.halt? do
          result = [%{"update_id" => 1, "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}}]
          Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
        else
          Test.HaltSemaphore.halt()

          result = []
          Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
        end
      end

      {:ok, bot} = Test.GoodBot.start_link()
      assert :ok == Test.Utils.wait_exit(bot)
    end

    test "response error", %{bypass: bypass} do
      Bypass.expect bypass, Test.Utils.http_method, Test.Utils.tg_path("getUpdates"), fn conn ->
        if Test.HaltSemaphore.halt? do
          result = [%{"update_id" => 1, "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}}]
          Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
        else
          Test.HaltSemaphore.halt()

          Test.Utils.put_json_resp(conn, 200, %{"ok" => false, "description" => "AZZ"})
        end
      end

      {:ok, bot} = Test.GoodBot.start_link()
      assert :ok == Test.Utils.wait_exit(bot)
    end
  end
end

defmodule Test.Telegram.BotSpecError do
  use ExUnit.Case, async: false

  setup do
    bypass = Bypass.open(port: Test.Utils.tg_port)

    on_exit fn ->
      Test.Utils.wait_bypass_exit(bypass)
    end

    {:ok, bypass: bypass}
  end

  test "Telegram.Bot wrong bot username", %{bypass: bypass} do
    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path("getMe"), fn conn ->
      result = %{"username" => "not_test_bot"}
      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    {:ok, bot} = Test.GoodBot.start()
    assert :ok == Test.Utils.wait_exit_with_ArgumentError(bot)
  end

  test "Bot with bad command list definition" do
    assert_raise ArgumentError, "expected list of commands as strings", fn ->
      Code.require_file "bad_bot.ex", __DIR__
    end
  end
end

defmodule Test.Telegram.BotBootstrap do
  use ExUnit.Case, async: false

  setup do
    bypass = Bypass.open(port: Test.Utils.tg_port)

    on_exit fn ->
      Test.Utils.wait_bypass_exit(bypass)
    end

    {:ok, bypass: bypass}
  end

  test "Telegram.Bot bootstrap getMe retries", %{bypass: bypass} do
    {:ok, _} = Test.HaltSemaphore.start_link()

    Bypass.expect bypass, Test.Utils.http_method, Test.Utils.tg_path("getMe"), fn conn ->
      if Test.HaltSemaphore.halt? do
        # second call
        result = %{"username" => "test_bot"}
        Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
      else
        # first call
        Test.HaltSemaphore.halt()

        Test.Utils.put_json_resp(conn, 500, %{"ok" => false, "description" => "500"})
      end
    end

    Bypass.expect bypass, Test.Utils.http_method, Test.Utils.tg_path("getUpdates"), fn conn ->
      result = [%{"update_id" => 1, "message" => %{"text" => "/halt", "from" => %{"username" => "tester"}}}]
      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    {:ok, bot} = Test.GoodBot.start()
    assert :ok == Test.Utils.wait_exit(bot)
  end
end

defmodule Test.Telegram.BotPurge do
  use ExUnit.Case, async: false

  setup do
    bypass = Bypass.open(port: Test.Utils.tg_port)

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path("getMe"), fn conn ->
      result = %{"username" => "test_bot"}
      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    on_exit fn ->
      Test.Utils.wait_bypass_exit(bypass)
    end

    {:ok, bypass: bypass}
  end

  test "Telegram.Bot purge old messages", %{bypass: bypass} do
    Bypass.expect bypass, Test.Utils.http_method, Test.Utils.tg_path("getUpdates"), fn conn ->
      now = DateTime.utc_now() |> DateTime.to_unix(:second)
      old = now - 1000

      {:ok, req_body, _} = Plug.Conn.read_body(conn)
      req = Poison.decode!(req_body)

      cond do
        req["offset"] == 4 ->
          result = [%{"update_id" => 4, "message" => %{"text" => "/halt", "date" => now, "from" => %{"username" => "tester"}}}]
          Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
        req["offset"] == 3 ->
          result = [%{"update_id" => 3, "message" => %{"text" => "OLD", "date" => old, "from" => %{"username" => "tester"}}}]
          Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
        req["offset"] == nil ->
          result = [%{"update_id" => 1, "message" => %{"text" => "OLD", "date" => old, "from" => %{"username" => "tester"}}},
                    %{"update_id" => 2, "message" => %{"text" => "OLD", "date" => old, "from" => %{"username" => "tester"}}}]
          Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
      end
    end

    {:ok, bot} = Test.PurgeBot.start()
    assert :ok == Test.Utils.wait_exit(bot)
  end
end
