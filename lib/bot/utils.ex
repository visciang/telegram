defmodule Telegram.Bot.Utils do
  @doc """
  Get the "from.user" field in an Update object, if any
  """
  @spec get_from_username(update :: map()) :: String.t() | nil
  def get_from_username(update) do
    Enum.find_value(update, fn
      {_update_type, %{"from" => %{"username" => username}}} ->
        username

      _ ->
        nil
    end)
  end

  @doc """
  Get the sent "date" field in an Update object, if any
  """
  @spec get_sent_date(update :: map()) :: DateTime.t() | nil
  def get_sent_date(update) do
    Enum.find_value(update, fn
      {_update_type, %{"date" => date}} ->
        # sent date is UTC
        DateTime.from_unix!(date, :second)

      _ ->
        nil
    end)
  end
end
