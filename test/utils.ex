defmodule Test.Utils do
  import ExUnit.Assertions, only: [assert_receive: 2, flunk: 1]

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
    Tesla.Mock.mock_global(fn request_env ->
      send(test_pid, {:tesla_mock_request_env, self(), request_env})

      receive do
        {:tesla_mock_response_env, response_env} ->
          response_env
      end
    end)
  end

  def tesla_mock_expect(fun, timeout \\ @retry_wait_period) do
    assert_receive {:tesla_mock_request_env, mock_pid, req_env}, timeout

    try do
      fun.(req_env)
    rescue
      FunctionClauseError ->
        {:no_match, req_env}
    else
      res_env ->
        send(mock_pid, {:tesla_mock_response_env, res_env})
        :ok
    end
  end
end
