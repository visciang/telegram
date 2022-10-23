defmodule Telegram.Bot.Dispatch do
  @moduledoc """
  Dispatch behaviour
  """

  alias Telegram.Types

  @type t :: module()

  @callback dispatch_update(Types.update(), Types.token()) :: :ok
end
