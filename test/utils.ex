defmodule Test.Utils do
  import ExUnit.Assertions, only: [assert_receive: 2]

  @base_url Application.get_env(:telegram, :api_base_url)
  @token "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
  @method "getFoo"

  @retry_wait_period Application.get_env(:telegram, :on_error_retry_delay) * 1000 + 500

  defmacro tg_token do
    quote do: unquote(@token)
  end

  defmacro http_method do
    quote do: unquote(:post)
  end

  defmacro tg_method() do
    quote do: unquote(@method)
  end

  defmacro tg_url(tg_method \\ @method) do
    quote do: unquote(@base_url) <> "/bot" <> unquote(@token) <> "/" <> unquote(tg_method)
  end

  def tesla_mock_global_async(test_pid) do
    Tesla.Mock.mock_global(fn request ->
      send(test_pid, {:tesla_mock_request, self(), request})

      receive do
        {:tesla_mock_response, response} ->
          response
      end
    end)
  end

  defmacro tesla_mock_expect_request(request_pattern, fun, timeout \\ @retry_wait_period) do
    quote do
      assert_receive {:tesla_mock_request, mock_pid, request = unquote(request_pattern)},
                     unquote(timeout)

      try do
        unquote(fun).(request)
      rescue
        FunctionClauseError ->
          {:no_match, request}
      else
        response ->
          send(mock_pid, {:tesla_mock_response, response})
          :ok
      end
    end
  end
end
