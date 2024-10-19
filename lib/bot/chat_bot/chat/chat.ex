defmodule Telegram.ChatBot.Chat do
  @moduledoc """
  A struct that represents a chat extracted from a Telegram update.
  Currently the only required field is `id`, any other data you may want to pass to
  `c:Telegram.ChatBot.init/1` should be included under the `metadata` field.
  """

  @type t() :: %__MODULE__{
          id: String.t(),
          metadata: Keyword.t(any())
        }

  @enforce_keys [:id]
  defstruct [:metadata] ++ @enforce_keys
end
