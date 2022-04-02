defmodule Telegram.Types do
  @moduledoc """
  Telegram types
  """

  @type token :: String.t()
  @type method :: String.t()
  @type update :: map()

  @type max_bot_concurrency :: non_neg_integer() | :infinity
end
