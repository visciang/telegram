defmodule Telegram.Types do
  @moduledoc """
  Telegram types
  """

  alias Telegram.Bot.Dispatch

  @default_max_bot_concurrency :infinity
  @default_allowed_updates []

  @type token :: String.t()
  @type method :: String.t()
  @type update :: map()

  @type max_bot_concurrency :: pos_integer() | :infinity

  @typedoc """
  Bot options.

  - `token`: bot token
  - `max_bot_concurrency`: maximum number of bots that can run concurrently. Defaults to `#{inspect(@default_max_bot_concurrency)}`.
  - `allowed_updates`: list of allowed updates (ref: https://core.telegram.org/bots/api#getupdates). Defaults to `#{inspect(@default_allowed_updates)}`.
  """
  @type bot_opts :: [
          token: token(),
          max_bot_concurrency: max_bot_concurrency(),
          allowed_updates: [String.t()]
        ]
  @type bot_spec :: {Dispatch.t(), bot_opts()}

  @type bot_routing :: %{
          token() => bot_behaviour :: module()
        }

  @spec default_max_bot_concurrency() :: max_bot_concurrency()
  def default_max_bot_concurrency, do: @default_max_bot_concurrency

  @spec default_allowed_updates() :: [String.t()]
  def default_allowed_updates, do: @default_allowed_updates
end
