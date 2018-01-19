defmodule Test.GoodBot do
  require Test.Utils

  use Telegram.Bot,
    token: Test.Utils.tg_token(),
    username: "test_bot",
    auth: ["tester"]

  command "halt", _ do
    halt "halt"
  end

  command "test1", [] do
    request "testResult", result: "ok test1"
  end

  command ["test2a", "test2b"], [] do
    request "testResult", result: "ok test2"
  end

  command "test3", ["a", "b"] do
    request "testResult", result: "ok test3"
  end

  command unknown do
    if match?("test4", unknown) do
      request "testResult", result: "ok test4"
    else
      request "testResult", result: "ko test4"
    end
  end

  message do
    if "test5" == update["text"] do
      request "testResult", result: "ok test5"
    else
      request "testResult", result: "ko test5"
    end
  end

  edited_message do
    if "test6" == update["text"] do
      request "testResult", result: "ok test6"
    else
      request "testResult", result: "ko test6"
    end
  end

  channel_post do
    if "test7" == update["text"] do
      request "testResult", result: "ok test7"
    else
      request "testResult", result: "ko test7"
    end
  end

  edited_channel_post do
    if "test8" == update["text"] do
      request "testResult", result: "ok test8"
    else
      request "testResult", result: "ko test8"
    end
  end

  callback_query do
    if "test9" == update["text"] do
      request "testResult", result: "ok test9"
    else
      request "testResult", result: "ko test9"
    end
  end

  shipping_query do
    if "test10" == update["text"] do
      request "testResult", result: "ok test10"
    else
      request "testResult", result: "ko test10"
    end
  end

  pre_checkout_query do
    if "test11" == update["text"] do
      request "testResult", result: "ok test11"
    else
      request "testResult", result: "ko test11"
    end
  end

  inline_query query do
    if "test12" == query do
      request "testResult", result: "ok test12"
    else
      request "testResult", result: "ko test12"
    end
  end

  chosen_inline_result query do
    if "test13" == query do
      request "testResult", result: "ok test13"
    else
      request "testResult", result: "ko test13"
    end
  end

  any do
    if "test14" == update["_any_"]["text"] do
      request "testResult", result: "ok test14"
    else
      request "testResult", result: "ko test14"
    end
  end
end
