# Telegram

[![.github/workflows/ci.yml](https://github.com/visciang/telegram/actions/workflows/ci.yml/badge.svg)](https://github.com/visciang/telegram/actions/workflows/ci.yml) [![Docs](https://img.shields.io/badge/docs-latest-green.svg)](https://visciang.github.io/telegram/readme.html) [![Coverage Status](https://coveralls.io/repos/github/visciang/telegram/badge.svg?branch=master)](https://coveralls.io/github/visciang/telegram?branch=master)

Telegram library for the Elixir language.

It provides:
- an inteface to the Telegram Bot HTTP-based APIs (`Telegram.Api`)
- a couple of bot behaviours to define you bots (`Telegram.Bot`, `Telegram.ChatBot`)
- two bot runners (`Telegram.Poller`, `Telegram.Webhook`)

## Installation

The package can be installed by adding `telegram` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telegram, github: "visciang/telegram", tag: "xxx"}
  ]
end
```

# Telegram Bot API

This module expose a light layer over the Telegram Bot API HTTP-based interface,
it does not expose any "(data)binding" over the HTTP interface and tries to abstract
away only the boilerplate for building / sending / serializing the API requests.

Compared to a full data-binded interface it could result less "typed frendly" but it will
work with any version of the Bot API, hopefully without updates or incompatibily
with new Bot API versions (as much as they remain backward compatible).


References:
* [API specification](https://core.telegram.org/bots/api)
* [Bot intro for developers](https://core.telegram.org/bots)

Given the token of your Bot you can issue any request using:
* method: Telegram API method name (ex. "getMe", "sendMessage")
* options: Telegram API method specific parameters (you can use Elixir's native types)

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

If an API parameter has a `InputFile` type and you want to send a local file,
for example a photo stored at "/tmp/photo.jpg", just wrap the parameter
value in a `{:file, "/tmp/photo.jpg"}` tuple. If the file content is in memory
wrap it in a `{:file_content, data, "photo.jpg"}` tuple.

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

## JSON-serialized object parameters

If an API parameter has a non primitive scalar type it is explicitly pointed out as "A JSON-serialized object"
(ie `InlineKeyboardMarkup`, `ReplyKeyboardMarkup`, etc).
In this case you can wrap the parameter value in a `{:json, value}` tuple.

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

## Quick start

Check the examples under `example/example_*.exs`.
You can run them as a `Mix` self-contained script.

```shell
BOT_TOKEN="..." example/example_chatbot.exs
```

## Bot updates processing

The Telegram platform supports two ways of processing bot updates, `getUpdates` and `setWebhook`.
`getUpdates` is a pull mechanism, `setWebhook` is a push mechanism. (ref: [bots webhook](https://core.telegram.org/bots/webhooks))

This library currently implements both models via two supervisors.

### Poller

This mode can be used in a dev environment or if your bot doesn't need to "scale". Being in pull it works well behind a firewall (or behind a home internet router).
Refer to the `Telegram.Poller` module docs for more info.


#### Telegram Client Config

The Telegram HTTP Client is based on `Tesla`.

The `Tesla.Adapter` and options should be configured via the `[:tesla, :adapter]` application environment key.
(ref. https://hexdocs.pm/tesla/readme.html#adapters)

For example, a good default could be:

```elixir
config :tesla, adapter: {Tesla.Adapter.Hackney, [recv_timeout: 40_000]}
```

a dependency should be added accordingly in your `mix.exs`:

```elixir
 defp deps do
    [
      {:telegram, github: "visciang/telegram", tag: "xxx"},
      {:hackney, "~> 1.18"},
      # ...
    ]
  end
```

### Webhook

This mode interfaces with the Telegram servers via a webhook, best for production use.
The app is meant to be served over HTTP, a reverse proxy should be placed in front of it, facing the public network over HTTPS.
It's possible to use two `Plug` compatible webserver: `Bandit` and `Plug.Cowboy`.

Alternatively, if you have a `Phoenix` / `Plug` based application facing internet, you can directly integrate the webhook.

Refer to the `Telegram.Webhook` module docs for more info.

## Dispatch model

We can define stateless / stateful bot.

* A stateless Bot has no memory of previous conversations, it just receives updates, process them and so on.

* A stateful Bot instead can remember what happened in the past.
The state here refer to a specific chat, a conversation (chat_id) between a user and a bot "instance".

## Bot behaviours

* `Telegram.Bot`: works with the **stateless async** dispatch model
* `Telegram.ChatBot`: works with the **stateful chat** dispatch model

## Logging

The library attaches two metadata fields to the internal logs: [:bot, :chat_id].
If your app runs more that one bot these fields can be included in your logs (ref. to the Logger config)
to clearly identify and "trace" every bot's message flow.

# Sample app

A chat_bot app, deployed to Gigalixir PaaS and served in webhook mode: https://github.com/visciang/telegram_example
