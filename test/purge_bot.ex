defmodule Test.PurgeBot do
  require Test.Utils

  use Telegram.Bot,
    token: Test.Utils.tg_token,
    username: "test_bot",
    auth: ["tester"],
    purge: true

  command "halt", _ do
    halt "halt"
  end

  any do
    request "testResult", result: "KO"
  end
end
