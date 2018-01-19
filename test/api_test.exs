defmodule Test.Telegram.Api do
  use ExUnit.Case, async: false
  require Test.Utils, as: Utils

  test "response ok" do
    result = %{"something" => [1, 2, 3]}
    response = %{"ok" => true, "result" => result}

    Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url()} ->
      Map.merge(%Tesla.Env{status: 200}, Utils.tesla_env_json(response))
    end)

    assert {:ok, result} == Telegram.Api.request(Utils.tg_token(), Utils.tg_method())
  end

  test "response not ok" do
    description = "desc"
    response = %{"ok" => false, "description" => description}

    Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url()} ->
      Map.merge(%Tesla.Env{status: 200}, Utils.tesla_env_json(response))
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

  test "request with parameters" do
    parameters = [par1: 1, par2: "aa", par3: %{"a" => 0}]
    request = Poison.encode!(Map.new(parameters))
    result = %{"something" => [1, 2, 3]}
    response = %{"ok" => true, "result" => result}

    Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url(), body: ^request} ->
      Map.merge(%Tesla.Env{status: 200}, Utils.tesla_env_json(response))
    end)

    assert {:ok, result} == Telegram.Api.request(Utils.tg_token(), Utils.tg_method(), parameters)
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
      Map.merge(%Tesla.Env{status: 200}, Utils.tesla_env_json(response))
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
      Map.merge(%Tesla.Env{status: 200}, Utils.tesla_env_json(response))
    end)

    assert {:ok, result} ==
             Telegram.Api.request(Test.Utils.tg_token(), Test.Utils.tg_method(), parameters)
  end

  test "request with 'json_markup' parameter" do
    parameters = [par1: 1, par2: {:json, %{"x" => "y"}}]
    request = Poison.encode!(Map.new(par1: 1, par2: ~s({"x":"y"})))
    result = %{"something" => [1, 2, 3]}
    response = %{"ok" => true, "result" => result}

    Tesla.Mock.mock(fn %{method: Utils.http_method(), url: Utils.tg_url(), body: ^request} ->
      Map.merge(%Tesla.Env{status: 200}, Utils.tesla_env_json(response))
    end)

    assert {:ok, result} ==
             Telegram.Api.request(Test.Utils.tg_token(), Test.Utils.tg_method(), parameters)
  end
end
