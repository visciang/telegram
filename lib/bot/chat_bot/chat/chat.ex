defmodule Telegram.ChatBot.Chat do
  @moduledoc """
  A struct that represents a chat extracted from a Telegram update.
  Currently the only required field is id, any other data should be included as keys under the metadata field keyword list.
  """

  @type t() :: %__MODULE__{
          id: String.t(),
          metadata: Keyword.t(any())
        }

  @enforce_keys [:id]
  defstruct [:metadata] ++ @enforce_keys
end
