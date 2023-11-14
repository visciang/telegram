defmodule Test.Telegram.Api do
  use ExUnit.Case, async: true
  import Test.Utils.Const

  describe "Test Telegram.Api.request" do
    test "response ok" do
      url = tg_url(tg_token(), tg_method())
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{method: :post, url: ^url} ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:ok, result} == Telegram.Api.request(tg_token(), tg_method())
    end

    test "response not ok" do
      url = tg_url(tg_token(), tg_method())
      description = "desc"
      response = %{"ok" => false, "description" => description}

      Tesla.Mock.mock(fn %{method: :post, url: ^url} ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:error, description} == Telegram.Api.request(tg_token(), tg_method())
    end

    test "response http error" do
      url = tg_url(tg_token(), tg_method())
      status = 500

      Tesla.Mock.mock(fn %{method: :post, url: ^url} ->
        %Tesla.Env{status: status}
      end)

      assert {:error, {:http_error, status}} ==
               Telegram.Api.request(tg_token(), tg_method())
    end

    test "response 429 ('too many requests' throttling)" do
      test_pid = self()
      url = tg_url(tg_token(), tg_method())
      error_description = "Too Many Requests"
      response = %{"ok" => false, "description" => error_description}

      Tesla.Mock.mock(fn %{method: :post, url: ^url} ->
        send(test_pid, :test_429)
        Tesla.Mock.json(response, status: 429)
      end)

      api_max_retries = Application.fetch_env!(:telegram, :api_max_retries)

      assert {:error, ^error_description} = Telegram.Api.request(tg_token(), tg_method())

      Enum.each(1..(api_max_retries + 1), fn _ ->
        assert_receive :test_429
      end)

      refute_received _
    end

    test "http adapter error" do
      url = tg_url(tg_token(), tg_method())

      Tesla.Mock.mock(fn %{method: :post, url: ^url} ->
        {:error, :reason}
      end)

      assert {:error, :reason} == Telegram.Api.request(tg_token(), tg_method())
    end

    test "request with parameters" do
      url = tg_url(tg_token(), tg_method())
      parameters = [par1: 1, par2: "aa", par3: %{"a" => 0}]
      request = Jason.encode!(Map.new(parameters))
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{method: :post, url: ^url, body: ^request} ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:ok, result} ==
               Telegram.Api.request(tg_token(), tg_method(), parameters)
    end

    test "request with 'file' parameter" do
      url = tg_url(tg_token(), tg_method())
      parameters = [par1: 1, par2: {:file, "mix.exs"}]
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{
                           method: :post,
                           url: ^url,
                           body: %Tesla.Multipart{
                             parts: [
                               %Tesla.Multipart.Part{body: "1", dispositions: [name: "par1"]},
                               %Tesla.Multipart.Part{
                                 body: %File.Stream{},
                                 dispositions: [name: "par2", filename: "mix.exs"]
                               }
                             ]
                           }
                         } ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:ok, result} ==
               Telegram.Api.request(tg_token(), tg_method(), parameters)
    end

    test "request with 'file_content' parameter" do
      url = tg_url(tg_token(), tg_method())
      parameters = [par1: 1, par2: {:file_content, "test", "test.txt"}]
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{
                           method: :post,
                           url: ^url,
                           body: %Tesla.Multipart{
                             parts: [
                               %Tesla.Multipart.Part{body: "1", dispositions: [name: "par1"]},
                               %Tesla.Multipart.Part{
                                 body: "test",
                                 dispositions: [name: "par2", filename: "test.txt"]
                               }
                             ]
                           }
                         } ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:ok, result} ==
               Telegram.Api.request(tg_token(), tg_method(), parameters)
    end

    test "request with 'json_markup' parameter" do
      url = tg_url(tg_token(), tg_method())
      parameters = [par1: 1, par2: {:json, %{"x" => "y"}}]
      request = Jason.encode!(Map.new(par1: 1, par2: ~s({"x":"y"})))
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{method: :post, url: ^url, body: ^request} ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:ok, result} ==
               Telegram.Api.request(tg_token(), tg_method(), parameters)
    end
  end

  describe "Test Telegram.Api.file" do
    test "ok" do
      method = :get
      token = tg_token()
      file_path = "file_path_test"
      url = "#{Application.get_env(:telegram, :api_base_url)}/file/bot#{token}/#{file_path}"
      file_content = File.read!("./test/assets/test.jpg")

      Tesla.Mock.mock(fn %{method: ^method, url: ^url} ->
        %Tesla.Env{
          status: 200,
          headers: [{"content-type", "application/octet-stream"}],
          body: file_content
        }
      end)

      assert {:ok, file_content} == Telegram.Api.file(token, file_path)
    end

    test "http adapter error" do
      method = :get
      token = tg_token()
      file_path = "file_path_test"
      url = "#{Application.get_env(:telegram, :api_base_url)}/file/bot#{token}/#{file_path}"

      Tesla.Mock.mock(fn %{method: ^method, url: ^url} ->
        {:error, :reason}
      end)

      assert {:error, :reason} == Telegram.Api.file(token, file_path)
    end

    test "http error" do
      method = :get
      token = tg_token()
      file_path = "file_path_test"
      url = "#{Application.get_env(:telegram, :api_base_url)}/file/bot#{token}/#{file_path}"

      Tesla.Mock.mock(fn %{method: ^method, url: ^url} ->
        %Tesla.Env{status: 404}
      end)

      assert {:error, {:http_error, 404}} == Telegram.Api.file(token, file_path)
    end
  end
end
