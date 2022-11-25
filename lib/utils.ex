defmodule Telegram.Utils do
  @moduledoc false

  require Logger

  @type retry_res :: {:ok, term()} | {:error, term()}

  @spec retry((() -> retry_res()), :infinity | non_neg_integer(), pos_integer()) :: retry_res()
  def retry(fun, times \\ :infinity, period \\ 1_000)

  def retry(fun, 0, _period) do
    fun.()
  end

  def retry(fun, times, period) do
    case fun.() do
      {:ok, _} = res ->
        res

      {:error, _} = err ->
        Logger.info("Api request failed with '#{inspect(err)}'. Retrying  in #{period} ms...")

        Process.sleep(period)

        times = if times == :infinity, do: :infinity, else: times - 1
        retry(fun, times, period)
    end
  end
end
