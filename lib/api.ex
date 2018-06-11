defmodule Telegram.Api do
  @moduledoc ~S"""
  Telegram Bot API request.

  The module expose a light layer over the Telegram Bot API HTTP-based interface,
  it does not expose any "(data)binding" over the HTTP interface and tries to abstract
  away only the boilerplate for building / sending / serializing the API requests.

  Compared to a full-binded interface it could result less elixir frendly but it will
  work with any version of the Bot API, hopefully without updates or incompatibily
  with new BOT API versions (as much as they remain backward compatible).


  References:
  - [API specification](https://core.telegram.org/bots/api)
  - [BOT intro for developers](https://core.telegram.org/bots)

  Given the token of your BOT you can issue any request using:
  - method: Telegram API method name (ex. "getMe", "sendMessage")
  - options: Telegram API method specific parameters (you can use elixir native types)

  ## Examples:

  Given the bot token (something like):

  ```elixir
  token = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
  ```

  ### [getMe](https://core.telegram.org/bots/api#getme)

  ```elixir
  Telegram.Api.request(token, "getMe")

  {:ok, %{"first_name" => "Abc", "id" => 1234567, "is_bot" => true, "username" => "ABC"}}
  ```

  ### [sendMessage](https://core.telegram.org/bots/api#sendmessage)

  ```elixir
  Telegram.Api.request(token, "sendMessage", chat_id: 876532, text: "Hello! .. silently", disable_notification: true)

  {:ok,
   %{"chat" => %{"first_name" => "Firstname",
       "id" => 208255328,
       "last_name" => "Lastname",
       "type" => "private",
       "username" => "xxxx"},
     "date" => 1505118722,
     "from" => %{"first_name" => "Yyy",
       "id" => 234027650,
       "is_bot" => true,
       "username" => "yyy"},
     "message_id" => 1402,
     "text" => "Hello! .. silently"}}
  ```

  ### [getUpdates](https://core.telegram.org/bots/api#getupdates)

  ```elixir
  Telegram.Api.request(token, "getUpdates", offset: -1, timeout: 30)

  {:ok,
   [%{"message" => %{"chat" => %{"first_name" => "Firstname",
          "id" => 208255328,
          "last_name" => "Lastname",
          "type" => "private",
          "username" => "xxxx"},
        "date" => 1505118098,
        "from" => %{"first_name" => "Firstname",
          "id" => 208255328,
          "is_bot" => false,
          "language_code" => "en-IT",
          "last_name" => "Lastname",
          "username" => "xxxx"},
        "message_id" => 1401,
        "text" => "Hello!"},
      "update_id" => 129745295}]}
  ```

  ## Sending files

  If a API parameter has a InputFile type and you want to send a local file,
  for example a photo stored locally at "/tmp/photo.jpg", just wrap the parameter
  value in a tuple `{:file, "/tmp/photo.jpg"}`. If the file content is in memory
  wrap it in {:file_content, data, "photo.jpg"} tuple.

  ### [sendPhoto](https://core.telegram.org/bots/api#sendphoto)

  ```elixir
  Telegram.Api.request(token, "sendPhoto", chat_id: 876532, photo: {:file, "/tmp/photo.jpg"})
  Telegram.Api.request(token, "sendPhoto", chat_id: 876532, photo: {:file_content, photo, "photo.jpg"})
  ```

  ## Downloading files

  To download a file from the telegram server you need a `file_path` pointer to the file.
  With that you can download the file via `Telegram.Api.file`

  ```elixir
  {:ok, res} = Telegram.Api.request(token, "sendPhoto", chat_id: 12345, photo: {:file, "example/photo.jpg"})
  # pick the 'file_obj' with the desired resolution
  [file_obj | _] = res["photo"]
  # get the 'file_id'
  file_id = file_obj["file_id"]
  ```

  ### [getFile](https://core.telegram.org/bots/api#getfile)

  ```elixir
  {:ok, %{"file_path" => file_path}} = Telegram.Api.request(token, "getFile", file_id: file_id)
  {:ok, file} = Telegram.Api.file(token, file_path)
  ```

  ## Reply Markup

  If a API parameter has a "A JSON-serialized object" type (InlineKeyboardMarkup, ReplyKeyboardMarkup, etc),
  just wrap the parameter value in a tuple `{:json, value}`.

  Reference: [Keyboards](https://core.telegram.org/bots#keyboards),
  [Inline Keyboards](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating)

  ### [sendMessage](https://core.telegram.org/bots/api#sendmessage) with keyboard

  ```elixir
  keyboard = [
    ["A0", "A1"],
    ["B0", "B1", "B2"]
  ]
  keyboard_markup = %{one_time_keyboard: true, keyboard: keyboard}
  Telegram.Api.request(token, "sendMessage", chat_id: 876532, text: "Here a keyboard!", reply_markup: {:json, keyboard_markup})
  ```
  """

  @type options :: Keyword.t()
  @type request_result :: {:ok, term} | {:error, term} | no_return()

  @doc """
  Send a Telegram Bot API request.

  Reference: [BOT Api](https://core.telegram.org/bots/api)
  """
  @spec request(Telegram.Api.Client.token(), Telegram.Api.Client.method(), options) ::
          request_result
  def request(token, method, options \\ []) do
    options = do_json_markup(options)

    if request_with_file?(options) do
      # body encoded as "multipart/form-data"
      Telegram.Api.Client.do_request(token, method, do_multipart_body(options))
    else
      # body encoded as "application/json"
      Telegram.Api.Client.do_request(token, method, Map.new(options))
    end
  end

  @doc """
  Download a file.

  Reference: [BOT Api](https://core.telegram.org/bots/api#file)

  Example:
  ```elixir
  # send a photo
  {:ok, res} = Telegram.Api.request(token, "sendPhoto", chat_id: 12345, photo: {:file, "example/photo.jpg"})
  # pick the 'file_obj' with the desired resolution
  [file_obj | _] = res["photo"]
  # get the 'file_id'
  file_id = file_obj["file_id"]

  # obtain the 'file_path' to dowload the file identified by 'file_id'
  {:ok, %{"file_path" => file_path}} = Telegram.Api.request(token, "getFile", file_id: file_id)
  {:ok, file} = Telegram.Api.file(token, file_path)
  ```
  """
  @spec file(Telegram.Api.Client.token(), Telegram.Api.Client.file_path()) :: request_result
  def file(token, file_path) do
    Telegram.Api.Client.do_file(token, file_path)
  end

  defp request_with_file?(options) do
    Enum.any?(
      options,
      &(match?({_name, {:file, _}}, &1) or match?({_name, {:file_content, _, _}}, &1))
    )
  end

  defp do_multipart_body(options) do
    Enum.reduce(options, Tesla.Multipart.new(), fn
      {name, {:file, file}}, multipart ->
        Tesla.Multipart.add_file(multipart, file, name: to_string(name))

      {name, {:file_content, file_content, filename}}, multipart ->
        Tesla.Multipart.add_file_content(multipart, file_content, filename, name: to_string(name))

      {name, value}, multipart ->
        Tesla.Multipart.add_field(multipart, to_string(name), to_string(value))
    end)
  end

  defp do_json_markup(options) do
    Enum.map(options, fn
      {name, {:json, value}} ->
        {name, Jason.encode!(value)}

      others ->
        others
    end)
  end
end

defmodule Telegram.Api.Client do
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

  def do_request(token, method, body) do
    result = post("/bot#{token}/#{method}", body)
    do_response(result)
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

  def do_file(token, file_path) do
    result = get("/file/bot#{token}/#{file_path}")
    do_file_response(result)
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
