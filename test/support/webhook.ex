defmodule Test.Webhook do
  @moduledoc false

  @webhook_base_url "http://localhost:4000"

  use Tesla, only: [:post], docs: false

  adapter Tesla.Adapter.Hackney

  plug Tesla.Middleware.BaseUrl, @webhook_base_url
  plug Tesla.Middleware.JSON

  @doc false
  def update(token, body) do
    "/__telegram_webhook__/#{token}"
    |> post(body)
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
