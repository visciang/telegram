defmodule Test.Utils.Const do
  @moduledoc false

  @base_url Application.compile_env(:telegram, :api_base_url)

  def tg_token, do: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
  def tg_method, do: "getFoo"
  def tg_url(token, method), do: "#{@base_url}/bot#{token}/#{method}"
end

defmodule Test.Utils.Mock do
  @moduledoc false

  @retry_wait_period Application.compile_env(:telegram, :get_updates_poll_timeout) * 1_000 + 500

  def tesla_mock_global_async(test_pid) do
    Tesla.Mock.mock_global(fn request ->
      send(test_pid, {:tesla_mock_request, self(), request})

      receive do
        {:tesla_mock_response, response} ->
          response
      end
    end)
  end

  defmacro tesla_mock_expect_request(request_pattern, fun, no_pending_requests \\ true) do
    quote do
      assert_receive({:tesla_mock_request, mock_pid, request = unquote(request_pattern)}, unquote(@retry_wait_period))

      try do
        unquote(fun).(request)
      rescue
        FunctionClauseError ->
          {:no_match, request}
      else
        response ->
          if unquote(no_pending_requests) do
            refute_received(_)
          end

          send(mock_pid, {:tesla_mock_response, response})
          :ok
      end
    end
  end

  defmacro tesla_mock_refute_request(request_pattern) do
    quote do
      refute_receive({:tesla_mock_request, mock_pid, request = unquote(request_pattern)}, unquote(@retry_wait_period))
      :ok
    end
  end
end
