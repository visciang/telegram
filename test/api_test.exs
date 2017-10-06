defmodule Test.Telegram.Api do
  use ExUnit.Case, async: false

  setup do
    bypass = Bypass.open(port: Test.Utils.tg_port)
    {:ok, bypass: bypass}
  end

  test "response ok", %{bypass: bypass} do
    result = %{"something" => [1, 2, 3]}

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path, fn conn ->
      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    assert {:ok, result} == Telegram.Api.request(Test.Utils.tg_token, Test.Utils.tg_method)
  end

  test "response not ok", %{bypass: bypass} do
    description = "desc"

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path, fn conn ->
      Test.Utils.put_json_resp(conn, 200, %{"ok" => false, "description" => description})
    end

    assert {:error, description} == Telegram.Api.request(Test.Utils.tg_token, Test.Utils.tg_method)
  end

  test "response http error", %{bypass: bypass} do
    status = 500

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path, fn conn ->
      Plug.Conn.resp(conn, status, "")
    end

    assert {:error, {:http_error, status}} == Telegram.Api.request(Test.Utils.tg_token, Test.Utils.tg_method)
  end

  test "request with parameters", %{bypass: bypass} do
    parameters = [par1: 1, par2: "aa", par3: %{"a" => 0}]
    result = %{"something" => [1, 2, 3]}

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path, fn conn ->
      {:ok, req_body, _} = Plug.Conn.read_body(conn)
      assert req_body == Poison.encode!(Map.new(parameters))
      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    assert {:ok, result} == Telegram.Api.request(Test.Utils.tg_token, Test.Utils.tg_method, parameters)
  end

  test "request with 'file' parameter", %{bypass: bypass} do
    parameters = [par1: 1, par2: {:file, "mix.exs"}]
    result = %{"something" => [1, 2, 3]}

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path, fn conn ->
      [content_type] = Plug.Conn.get_req_header(conn, "content-type")
      assert content_type =~ ~r(multipart/form-data; boundary=.+)

      # we should decode the multipart data and check that everything is there ..
      {:ok, req_body, _} = Plug.Conn.read_body(conn)
      assert String.length(req_body) > 0

      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    assert {:ok, result} == Telegram.Api.request(Test.Utils.tg_token, Test.Utils.tg_method, parameters)
  end

  test "request with 'file_content' parameter", %{bypass: bypass} do
    parameters = [par1: 1, par2: {:file_content, "test", "test.txt"}]
    result = %{"something" => [1, 2, 3]}

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path, fn conn ->
      [content_type] = Plug.Conn.get_req_header(conn, "content-type")
      assert content_type =~ ~r(multipart/form-data; boundary=.+)

      # we should decode the multipart data and check that everything is there ..
      {:ok, req_body, _} = Plug.Conn.read_body(conn)
      assert String.length(req_body) > 0

      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    assert {:ok, result} == Telegram.Api.request(Test.Utils.tg_token, Test.Utils.tg_method, parameters)
  end

  test "request with 'json_markup' parameter", %{bypass: bypass} do
    parameters = [par1: 1, par2: {:json, %{"x" => "y"}}]
    result = %{"something" => [1, 2, 3]}

    Bypass.expect_once bypass, Test.Utils.http_method, Test.Utils.tg_path, fn conn ->
      {:ok, req_body, _} = Plug.Conn.read_body(conn)
      assert req_body == Poison.encode!(Map.new([par1: 1, par2: ~s({"x":"y"})]))
      Test.Utils.put_json_resp(conn, 200, %{"ok" => true, "result" => result})
    end

    assert {:ok, result} == Telegram.Api.request(Test.Utils.tg_token, Test.Utils.tg_method, parameters)
  end
end
