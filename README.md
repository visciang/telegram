# Telegram

![CI](https://github.com/visciang/telegram/workflows/CI/badge.svg) [![Docs](https://img.shields.io/badge/docs-latest-green.svg)](https://visciang.github.io/telegram/readme.html) [![Coverage Status](https://coveralls.io/repos/github/visciang/telegram/badge.svg?branch=master)](https://coveralls.io/github/visciang/telegram?branch=github-actions)

Telegram library for the Elixir language.

## Installation

The package can be installed by adding `telegram` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telegram, git: "https://github.com/visciang/telegram.git", tag: "xxx"}
  ]
end
```

# Telegram API

Telegram Bot API request.

The module expose a light layer over the Telegram Bot API HTTP-based interface,
it does not expose any "(data)binding" over the HTTP interface and tries to abstract
away only the boilerplate for building / sending / serializing the API requests.

Compared to a full-binded interface it could result less elixir frendly but it will
work with any version of the Bot API, hopefully without updates or incompatibily
with new Bot API versions (as much as they remain backward compatible).


References:
* [API specification](https://core.telegram.org/bots/api)
* [Bot intro for developers](https://core.telegram.org/bots)

Given the token of your Bot you can issue any request using:
* method: Telegram API method name (ex. "getMe", "sendMessage")
* options: Telegram API method specific parameters (you can use elixir native types)

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
wrap it in `{:file_content, data, "photo.jpg"}` tuple.

### [sendPhoto](https://core.telegram.org/bots/api#sendphoto)

```elixir
Telegram.Api.request(token, "sendPhoto", chat_id: 876532, photo: {:file, "/tmp/photo.jpg"})
Telegram.Api.request(token, "sendPhoto", chat_id: 876532, photo: {:file_content, photo, "photo.jpg"})
```

## Downloading files

To download a file from the telegram server you need a `file_path` pointer to the file.
With that you can download the file via `Telegram.Api.file`.

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

# Telegram Bot

A simple Bot behaviour.

## Example

See [example bot](example/example.exs).

## Telegram Bot Supervisor

The `Telegram.Bot.Supervisor` is responsible to run `Telegram.Bot` behaviours.

You can run multiple `Telegram.Bot` behaviours under your supervisor with different options.

The  `Telegram.Bot.Supervisor` execution model (concurrently) dispatch every received update to a worker process
(up to `max_bot_concurrency`) handling updates with the provider `Telegram.Bot` behaviour module.
With this execution model every update processing is isolated.

Currently no "chat statefull session" concept is implemented in the `Telegram.Bot.Supervisor`,
but you can easely build one on top of this basic dispatch machinery.

```elixir
token_hello_bot = "your Bot authentication token"    # required
token_time_bot = "...."

options = [
  max_bot_concurrency: 1_000,    # max concurrent worker processing updates for this bot
  purge: true,                   # [optional] purge old messages at startup
]

# start 2 bot: HelloBot and TimeBot
children = [
  {Telegram.Bot.Supervisor, {HelloBot, token_hello_bot, options}},
  {Telegram.Bot.Supervisor, {TimeBot, token_time_bot, options}}
]
opts = [strategy: :one_for_one, name: MyApplication.Supervisor]
Supervisor.start_link(children, opts)
```
