defmodule Test.Utils do
  def tg_port, do: 8000
  def tg_token, do: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
  def tg_method, do: "getFoo"
  def tg_path, do: "/bot" <> tg_token() <> "/" <> tg_method()
  def tg_path(method), do: "/bot" <> tg_token() <> "/" <> method
  def http_method, do: "POST"

  def put_json_resp(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Poison.encode!(body))
  end

  def wait_exit(proc) do
    ref = Process.monitor(proc)

    receive do
      {:DOWN, ^ref, :process, _object, :normal} ->
        :ok
    after
      # should be > Telegram.Bot.@retry_quiet_period
      10000 ->
        :error
    end
  end

  def wait_exit_with_ArgumentError(proc) do
    ref = Process.monitor(proc)

    receive do
      {:DOWN, ^ref, :process, _object, {%ArgumentError{}, _}} ->
        :ok
    after
      10000 ->
        :error
    end
  end

  def wait_socket_release() do
    # https://github.com/PSPDFKit-labs/bypass/issues/51
    Process.sleep(200)
  end
end
