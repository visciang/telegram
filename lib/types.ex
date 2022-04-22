defmodule Telegram.Types do
  @moduledoc """
  Telegram types
  """

  @type token :: String.t()
  @type method :: String.t()
  @type update :: map()

  @type max_bot_concurrency :: pos_integer() | :infinity
  @type bot_opts :: [token: token(), max_bot_concurrency: max_bot_concurrency()]
  @type bot_spec :: {module(), bot_opts()}
end
