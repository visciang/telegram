defmodule Test.Utils.Const do
  @moduledoc false

  @base_url Application.compile_env(:telegram, :api_base_url)

  def tg_token(test_pid \\ self()), do: pid_to_string(test_pid)
  def tg_method, do: "getFoo"
  def tg_url(token, method), do: "#{@base_url}/bot#{token}/#{method}"

  def pid_to_string(pid), do: pid |> :erlang.pid_to_list() |> to_string()
  def string_to_pid(pid_string), do: pid_string |> to_charlist() |> :erlang.list_to_pid()
end

defmodule Test.Utils.Mock do
  @moduledoc false

  alias Test.Utils.Const

  @retry_wait_period Application.compile_env(:telegram, :get_updates_poll_timeout) * 1_000 + 500

  def tesla_mock_global_async do
    Tesla.Mock.mock_global(fn %{url: url} = request ->
      test_pid = get_test_pid_from_request_url(url)

      send(test_pid, {:tesla_mock_request, self(), request})

      receive do
        {:tesla_mock_response, response} ->
          response
      end
    end)
  end

  defmacro tesla_mock_expect_request(request_pattern, fun_process_req_resp, no_pending_requests \\ true) do
    quote do
      assert_receive({:tesla_mock_request, mock_pid, request = unquote(request_pattern)}, unquote(@retry_wait_period))

      try do
        unquote(fun_process_req_resp).(request)
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

  defp get_test_pid_from_request_url(url) do
    # ex:  url = "http://test:8000/bot<0.422.0>/testResponse"
    %{"test_pid" => test_pid} = Regex.named_captures(~r"/bot(?<test_pid>[^/]+)/", url)
    Const.string_to_pid(test_pid)
  end
end

defmodule Test.Utils.Poller do
  defmacro assert_webhook_setup(token) do
    quote do
      require Test.Utils.Const

      url_get_webhook_info = tg_url(unquote(token), "getWebhookInfo")
      url_delete_webhook = tg_url(unquote(token), "deleteWebhook")

      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url_get_webhook_info},
                 fn _ ->
                   response = %{"ok" => true, "result" => %{"url" => "url"}}
                   Tesla.Mock.json(response, status: 200)
                 end
               )

      assert :ok ==
               tesla_mock_expect_request(
                 %{method: :post, url: ^url_delete_webhook},
                 fn _ ->
                   response = %{"ok" => true, "result" => true}
                   Tesla.Mock.json(response, status: 200)
                 end
               )
    end
  end
end
