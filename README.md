# Telegram

[![Build Status](https://travis-ci.org/visciang/telegram.svg?branch=master)](https://travis-ci.org/visciang/telegram) [![Docs](https://img.shields.io/badge/docs-latest-green.svg)](https://visciang.github.io/telegram/readme.html) [![Coverage Status](https://coveralls.io/repos/github/visciang/telegram/badge.svg)](https://coveralls.io/github/visciang/telegram)


Telegram library for the Elixir language.

## Installation

The package can be installed by adding `telegram` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telegram, git: "https://github.com/visciang/telegram.git", tag: "0.2.1"}
  ]
end
```

## Telegram API

Telegram Bot API request.

The module expose a light layer over the Telegram Bot API HTTP-based interface,
it does not expose any "(data)binding" over the HTTP interface and tries to abstract
away only the boilerplate for building / sending / serializing the API requests.

Compared to a full-binded interface it could result less elixir frendly but it will
work with any version of the Bot API, hopefully without updates or incompatibily
with new BOT API versions (as much as they remain backward compatible).


References:
* [API specification](https://core.telegram.org/bots/api)
* [BOT intro for developers](https://core.telegram.org/bots)

Given the token of your BOT you can issue any request using:
* method: Telegram API method name (ex. "getMe", "sendMessage")
* options: Telegram API method specific parameters (you can use elixir native types)

### Examples:

Given the bot token (something like):

```elixir
token = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
```

#### [getMe](https://core.telegram.org/bots/api#getme)

```elixir
Telegram.Api.request(token, "getMe")

{:ok, %{"first_name" => "Abc", "id" => 1234567, "is_bot" => true, "username" => "ABC"}}
```

#### [sendMessage](https://core.telegram.org/bots/api#sendmessage)

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

#### [getUpdates](https://core.telegram.org/bots/api#getupdates)

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

### Sending files

If a API parameter has a InputFile type and you want to send a local file,
for example a photo stored locally at "/tmp/photo.jpg", just wrap the parameter
value in a tuple `{:file, "/tmp/photo.jpg"}`.

#### [sendPhoto](https://core.telegram.org/bots/api#sendphoto)

```elixir
Telegram.Api.request(token, "sendPhoto", chat_id: 876532, photo: {:file, "/tmp/photo.jpg"})
```

### Reply Markup

If a API parameter has a "A JSON-serialized object" type (InlineKeyboardMarkup, ReplyKeyboardMarkup, etc),
just wrap the parameter value in a tuple `{:json, value}`.

Reference: [Keyboards](https://core.telegram.org/bots#keyboards),
[Inline Keyboards](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating)

#### [sendMessage](https://core.telegram.org/bots/api#sendmessage) with keyboard

```elixir
keyboard = [
  ["A0", "A1"],
  ["B0", "B1", "B2"]
]
keyboard_markup = %{one_time_keyboard: true, keyboard: keyboard}
Telegram.Api.request(token, "sendMessage", chat_id: 876532, text: "Here a keyboard!", reply_markup: {:json, keyboard_markup})
```

## Telegram BOT

A simple BOT behaviour and DSL.

## Example

```elixir
defmodule Simple.Bot do
  use Telegram.Bot,
    token: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11",
    username: "simple_bot",
    auth: ["user1", "user2"]

  command ["ciao", "hello"], args do
    # handle the commands: "/ciao" and "/hello"

    # reply with a text message
    request "sendMessage",
      chat_id: update["chat"]["id"],
      text: "ciao! #{inspect args}"
  end

  command unknown do
    request "sendMessage", chat_id: update["chat"]["id"],
      text: "Unknow command `#{unknown}`"
  end

  message do
    request "sendMessage", chat_id: update["chat"]["id"],
      text: "Hey! You sent me a message: #{inspect update}"
  end

  edited_message do
    # handler code
  end

  channel_post do
    # handler code
  end

  edited_channel_post do
    # handler code
  end

  inline_query _query do
    # handler code
  end

  chosen_inline_result _query do
    # handler code
  end

  callback_query do
    # handler code
  end

  shipping_query do
    # handler code
  end

  pre_checkout_query do
    # handler code
  end

  any do
    # handler code
  end
end
```

See `Telegram.Bot.Dsl` documentation for all available macros.

## Options

```elixir
use Telegram.Bot,
  token: "your bot auth token",   # required
  username: "your bot username",  # required
  auth: ["user1", "user2"],       # optional, list of authorized users
                                  # or authorizing function (String.t -> boolean)
  restart: policy                 # optional, default :permanent
```

## Execution model

The bot defined using the `Telegram.Bot` behaviour is based on `Task`
and will run in a single erlang process, processing updates sequentially.

You can add the bot to you application supervisor tree, for example:

```elixir
children = [Simple.Bot, ...]
opts = [strategy: :one_for_one, name: MyApplication.Supervisor]
Supervisor.start_link(children, opts)
```

or directly start and link the bot with:

```elixir
{:ok, pid} = Simple.Bot.start_link()
```
