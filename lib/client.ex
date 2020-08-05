defmodule Telegram.Client do
  @moduledoc false

  @type token :: String.t()
  @type method :: String.t()
  @type file_path :: String.t()
  @type body :: map() | Tesla.Multipart.t()

  @api_base_url Application.compile_env(:telegram, :api_base_url, "https://api.telegram.org")

  use Tesla, only: [:get, :post], docs: false

  if Application.compile_env(:telegram, :mock) == true do
    adapter Tesla.Mock
  else
    @recv_timeout Application.compile_env(:telegram, :recv_timeout, 60) * 1000
    @connect_timeout Application.compile_env(:telegram, :connect_timeout, 5) * 1000

    adapter Tesla.Adapter.Gun, timeout: @recv_timeout, connect_timeout: @connect_timeout
  end

  plug Tesla.Middleware.BaseUrl, @api_base_url
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Retry

  @doc false
  @spec do_request(token(), method(), body()) :: {:ok, term()} | {:error, term()}
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
  @spec do_file(token(), file_path()) :: {:ok, Tesla.Env.body()} | {:error, term()}
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
