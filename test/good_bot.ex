defmodule Test.GoodBot do
  use Telegram.Bot,
    token: Test.Utils.tg_token,
    username: "test_bot",
    auth: ["tester"]

  command "halt", _ do
    halt "halt"
  end

  command "test1", args do
    [] = args
    request "testResult", result: "ok test1"
  end

  command ["test2a", "test2b"], args do
    [] = args
    request "testResult", result: "ok test2"
  end

  command "test3", ["a", "b"] do
    request "testResult", result: "ok test3"
  end

  command unknown do
    "test4" = unknown
    request "testResult", result: "ok test4"
  end

  message do
    "test5" = update["text"]
    request "testResult", result: "ok test5"
  end

  edited_message do
    "test6" = update["text"]
    request "testResult", result: "ok test6"
  end

  channel_post do
    "test7" = update["text"]
    request "testResult", result: "ok test7"
  end

  edited_channel_post do
    "test8" = update["text"]
    request "testResult", result: "ok test8"
  end

  callback_query do
    "test9" = update["text"]
    request "testResult", result: "ok test9"
  end

  shipping_query do
    "test10" = update["text"]
    request "testResult", result: "ok test10"
  end

  pre_checkout_query do
    "test11" = update["text"]
    request "testResult", result: "ok test11"
  end

  inline_query query do
    "test12" = query
    request "testResult", result: "ok test12"
  end

  chosen_inline_result query do
    "test13" = query
    request "testResult", result: "ok test13"
  end

  any do
    "test14" = update["_any_"]["text"]
    request "testResult", result: "ok test14"
  end
end
