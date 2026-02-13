defmodule Telegram.Client do
  @moduledoc false

  @type file_path :: String.t()
  @type body :: map() | Tesla.Multipart.t()

  @api_base_url Application.compile_env(:telegram, :api_base_url, "https://api.telegram.org")
  @api_max_retries Application.compile_env(:telegram, :api_max_retries, 5)

  require Logger

  defp client do
    middleware = [
      {Tesla.Middleware.BaseUrl, @api_base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Retry,
       max_retries: @api_max_retries,
       should_retry: fn
         {:ok, %{status: 429}} ->
           Logger.warning("Telegram API throttling, HTTP 429 'Too Many Requests'")
           true

         {:ok, _} ->
           false

         {:error, _} ->
           true
       end}
    ]

    Tesla.client(middleware)
  end

  @doc false
  @spec request(Telegram.Types.token(), Telegram.Types.method(), body()) :: {:ok, term()} | {:error, term()}
  def request(token, method, body) do
    "/bot#{token}/#{method}"
    |> then(&Tesla.post(client(), &1, body))
    |> process_response()
  end

  @doc false
  @spec file(Telegram.Types.token(), file_path()) :: {:ok, Tesla.Env.body()} | {:error, term()}
  def file(token, file_path) do
    "/file/bot#{token}/#{file_path}"
    |> then(&Tesla.get(client(), &1))
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
