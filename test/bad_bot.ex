defmodule Test.BadBot do
  use Telegram.Bot,
    token: "token",
    username: "username"

  command ["a", :not_a_string], _args do
    :ok
  end
end
