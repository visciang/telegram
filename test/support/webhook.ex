defmodule Test.Webhook do
  @moduledoc false

  @webhook_base_url "http://localhost:4000"

  defp client do
    middleware = [
      {Tesla.Middleware.BaseUrl, @webhook_base_url},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware, Tesla.Adapter.Hackney)
  end

  @doc false
  def update(token, body) do
    "/__telegram_webhook__/#{token}"
    |> then(&Tesla.post(client(), &1, body))
    |> process_response()
  end

  defp process_response({:ok, env}) do
    case env.status do
      200 ->
        {:ok, env.body}

      status ->
        {:error, {:http_error, status}}
    end
  end
end
