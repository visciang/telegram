defmodule Telegram.Client do
  @moduledoc false

  @type file_path :: String.t()
  @type body :: map() | Tesla.Multipart.t()

  @api_base_url Application.compile_env(:telegram, :api_base_url, "https://api.telegram.org")

  use Tesla, only: [:get, :post], docs: false

  if Mix.env() == :test do
    adapter Tesla.Mock
  else
    adapter Tesla.Adapter.Gun, timeout: 60_000, connect_timeout: 5_000, certificates_verification: true
  end

  plug Tesla.Middleware.BaseUrl, @api_base_url
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Retry

  @doc false
  @spec request(Telegram.Types.token(), Telegram.Types.method(), body()) :: {:ok, term()} | {:error, term()}
  def request(token, method, body) do
    "/bot#{token}/#{method}"
    |> post(body)
    |> process_response()
  end

  @doc false
  @spec file(Telegram.Types.token(), file_path()) :: {:ok, Tesla.Env.body()} | {:error, term()}
  def file(token, file_path) do
    "/file/bot#{token}/#{file_path}"
    |> get()
    |> process_file_response()
  end

  defp process_response({:ok, env}) do
    case env.body do
      %{"ok" => true, "result" => result} ->
        {:ok, result}

      %{"ok" => false, "description" => description} ->
        {:error, description}

      _ ->
        {:error, {:http_error, env.status}}
    end
  end

  defp process_response({:error, reason}) do
    {:error, reason}
  end

  defp process_file_response({:ok, env}) do
    case env.status do
      200 ->
        {:ok, env.body}

      status ->
        {:error, {:http_error, status}}
    end
  end

  defp process_file_response({:error, reason}) do
    {:error, reason}
  end
end
