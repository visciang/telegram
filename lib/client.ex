defmodule Telegram.Client do
  @type token :: String.t()
  @type method :: String.t()
  @type file_path :: String.t()

  @api_base_url Application.get_env(:telegram, :api_base_url, "https://api.telegram.org")
  # timeout configuration opts unit: seconds
  @recv_timeout Application.get_env(:telegram, :recv_timeout, 60) * 1000
  @connect_timeout Application.get_env(:telegram, :connect_timeout, 5) * 1000

  use Tesla, only: [:get, :post], docs: false

  if Application.get_env(:telegram, :mock) == true do
    adapter Tesla.Mock
  else
    adapter Tesla.Adapter.Hackney
  end

  plug Tesla.Middleware.Opts, recv_timeout: @recv_timeout, connect_timeout: @connect_timeout
  plug Tesla.Middleware.BaseUrl, @api_base_url
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Retry

  @doc false
  def do_request(token, method, body) do
    "/bot#{token}/#{method}"
    |> post(body)
    |> do_response()
  end

  defp do_response({:ok, env}) do
    case env.body do
      %{"ok" => true, "result" => result} ->
        {:ok, result}

      %{"ok" => false, "description" => description} ->
        {:error, description}

      _ ->
        {:error, {:http_error, env.status}}
    end
  end

  defp do_response({:error, reason}) do
    {:error, reason}
  end

  @doc false
  def do_file(token, file_path) do
    "/file/bot#{token}/#{file_path}"
    |> get()
    |> do_file_response()
  end

  defp do_file_response({:ok, env}) do
    case env.status do
      200 ->
        {:ok, env.body}

      status ->
        {:error, {:http_error, status}}
    end
  end

  defp do_file_response({:error, reason}) do
    {:error, reason}
  end
end
