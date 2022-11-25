defmodule Test.Telegram.Utils do
  use ExUnit.Case, async: true
  alias Telegram.Utils

  require Logger

  test "retry" do
    test_pid = self()

    task =
      Task.async(fn ->
        fun = fn ->
          send(test_pid, {:retry, self()})

          receive do
            :cont -> {:error, nil}
            :halt -> {:ok, nil}
          end
        end

        Utils.retry(fun, :infinity, 10)
      end)

    receive do
      {:retry, pid} -> send(pid, :cont)
    after
      5_000 -> flunk("timeout")
    end

    receive do
      {:retry, pid} -> send(pid, :halt)
    after
      5_000 -> flunk("timeout")
    end

    assert {:ok, nil} = Task.await(task)
  end

  test "no retry" do
    fun = fn -> {:error, nil} end

    task =
      Task.async(fn ->
        Utils.retry(fun, 0, 10)
      end)

    assert {:error, nil} = Task.await(task)
  end
end
