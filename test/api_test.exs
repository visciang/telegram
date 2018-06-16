defmodule Test.Telegram.Api do
  use ExUnit.Case, async: false
  require Test.Utils, as: Utils

  describe "Test Telegram.Api.request" do
    test "response ok" do
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url()} ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:ok, result} == Telegram.Api.request(Utils.tg_token(), Utils.tg_method())
    end

    test "response not ok" do
      description = "desc"
      response = %{"ok" => false, "description" => description}

      Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url()} ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:error, description} == Telegram.Api.request(Utils.tg_token(), Utils.tg_method())
    end

    test "response http error" do
      status = 500

      Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url()} ->
        %Tesla.Env{status: status}
      end)

      assert {:error, {:http_error, status}} ==
               Telegram.Api.request(Utils.tg_token(), Utils.tg_method())
    end

    test "http adapter error" do
      Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url()} ->
        {:error, :reason}
      end)

      assert {:error, :reason} == Telegram.Api.request(Utils.tg_token(), Utils.tg_method())
    end

    test "request with parameters" do
      parameters = [par1: 1, par2: "aa", par3: %{"a" => 0}]
      request = Jason.encode!(Map.new(parameters))
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url(), body: ^request} ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:ok, result} ==
               Telegram.Api.request(Utils.tg_token(), Utils.tg_method(), parameters)
    end

    test "request with 'file' parameter" do
      parameters = [par1: 1, par2: {:file, "mix.exs"}]
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{
                           method: Utils.http_method(),
                           url: Utils.tg_url(),
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
               Telegram.Api.request(Test.Utils.tg_token(), Test.Utils.tg_method(), parameters)
    end

    test "request with 'file_content' parameter" do
      parameters = [par1: 1, par2: {:file_content, "test", "test.txt"}]
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{
                           method: Utils.http_method(),
                           url: Utils.tg_url(),
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
               Telegram.Api.request(Test.Utils.tg_token(), Test.Utils.tg_method(), parameters)
    end

    test "request with 'json_markup' parameter" do
      parameters = [par1: 1, par2: {:json, %{"x" => "y"}}]
      request = Jason.encode!(Map.new(par1: 1, par2: ~s({"x":"y"})))
      result = %{"something" => [1, 2, 3]}
      response = %{"ok" => true, "result" => result}

      Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url(), body: ^request} ->
        Tesla.Mock.json(response, status: 200)
      end)

      assert {:ok, result} ==
               Telegram.Api.request(Test.Utils.tg_token(), Test.Utils.tg_method(), parameters)
    end
  end

  describe "Test Telegram.Api.file" do
    test "ok" do
      method = :get
      token = "token_test"
      file_path = "file_path_test"
      url = "#{Application.get_env(:telegram, :api_base_url)}/file/bot#{token}/#{file_path}"
      file_content = File.read!("./example/photo.jpg")

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
      token = "token_test"
      file_path = "file_path_test"
      url = "#{Application.get_env(:telegram, :api_base_url)}/file/bot#{token}/#{file_path}"

      Tesla.Mock.mock(fn %{method: ^method, url: ^url} ->
        {:error, :reason}
      end)

      assert {:error, :reason} == Telegram.Api.file(token, file_path)
    end

    test "http error" do
      method = :get
      token = "token_test"
      file_path = "file_path_test"
      url = "#{Application.get_env(:telegram, :api_base_url)}/file/bot#{token}/#{file_path}"

      Tesla.Mock.mock(fn %{method: ^method, url: ^url} ->
        %Tesla.Env{status: 404}
      end)

      assert {:error, {:http_error, 404}} == Telegram.Api.file(token, file_path)
    end
  end
end
