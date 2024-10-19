defmodule Telegram.ChatBot.Chat do
  @moduledoc """

  """

  @type t() :: %__MODULE__{
    id: String.t(),
    metadata: Keyword.t(any())
  }

  @enforce_keys [:id]
  defstruct [:metadata] ++ @enforce_keys
end
