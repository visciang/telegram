defmodule Telegram.Bot.Dispatch do
  @moduledoc false

  alias Telegram.Types

  @type t :: module()

  @callback dispatch_update(Types.update(), Types.token()) :: :ok
end
