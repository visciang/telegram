searchData={"items":[{"type":"module","title":"Telegram.Api","doc":"Telegram Bot API - HTTP-based interface","ref":"Telegram.Api.html"},{"type":"function","title":"Telegram.Api.file/2","doc":"Download a file.\n\nReference: [BOT Api](https://core.telegram.org/bots/api#file)\n\nExample:\n\n```elixir\n# send a photo\n{:ok, res} = Telegram.Api.request(token, \"sendPhoto\", chat_id: 12345, photo: {:file, \"example/photo.jpg\"})\n# pick the 'file_obj' with the desired resolution\n[file_obj | _] = res[\"photo\"]\n# get the 'file_id'\nfile_id = file_obj[\"file_id\"]\n\n# obtain the 'file_path' to download the file identified by 'file_id'\n{:ok, %{\"file_path\" => file_path}} = Telegram.Api.request(token, \"getFile\", file_id: file_id)\n{:ok, file} = Telegram.Api.file(token, file_path)\n```","ref":"Telegram.Api.html#file/2"},{"type":"function","title":"Telegram.Api.request/3","doc":"Send a Telegram Bot API request.\n\nThe request `parameters` map to the bots API parameters.\n\n- `Integer String Boolean Float`: Elixir native data type\n- `JSON-serialized`: `{:json, _}` tuple\n- `InputFile`: `{:file, _}` or `{:file_content, _, _}` tuple\n\nReference: [BOT Api](https://core.telegram.org/bots/api)","ref":"Telegram.Api.html#request/3"},{"type":"type","title":"Telegram.Api.parameter_name/0","doc":"","ref":"Telegram.Api.html#t:parameter_name/0"},{"type":"type","title":"Telegram.Api.parameter_value/0","doc":"","ref":"Telegram.Api.html#t:parameter_value/0"},{"type":"type","title":"Telegram.Api.parameters/0","doc":"","ref":"Telegram.Api.html#t:parameters/0"},{"type":"type","title":"Telegram.Api.request_result/0","doc":"","ref":"Telegram.Api.html#t:request_result/0"},{"type":"behaviour","title":"Telegram.Bot","doc":"Telegram Bot behaviour.","ref":"Telegram.Bot.html"},{"type":"behaviour","title":"Example - Telegram.Bot","doc":"```elixir\ndefmodule HelloBot do\n  use Telegram.Bot\n\n  @impl Telegram.Bot\n  def handle_update(\n    %{\"message\" => %{\"text\" => \"/hello\", \"chat\" => %{\"id\" => chat_id, \"username\" => username}, \"message_id\" => message_id}},\n    token\n  ) do\n    Telegram.Api.request(token, \"sendMessage\",\n      chat_id: chat_id,\n      reply_to_message_id: message_id,\n      text: \"Hello #{username}!\"\n    )\n  end\n\n  def handle_update(_update, _token) do\n    # ignore unknown updates\n\n    :ok\n  end\nend\n```","ref":"Telegram.Bot.html#module-example"},{"type":"callback","title":"Telegram.Bot.handle_update/2","doc":"The function receives the telegram update event.","ref":"Telegram.Bot.html#c:handle_update/2"},{"type":"behaviour","title":"Telegram.Bot.Dispatch","doc":"Dispatch behaviour","ref":"Telegram.Bot.Dispatch.html"},{"type":"callback","title":"Telegram.Bot.Dispatch.dispatch_update/2","doc":"","ref":"Telegram.Bot.Dispatch.html#c:dispatch_update/2"},{"type":"type","title":"Telegram.Bot.Dispatch.t/0","doc":"","ref":"Telegram.Bot.Dispatch.html#t:t/0"},{"type":"module","title":"Telegram.Bot.Utils","doc":"Bot utilities","ref":"Telegram.Bot.Utils.html"},{"type":"function","title":"Telegram.Bot.Utils.get_chat/1","doc":"Get the \"chat\" field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_chat/1"},{"type":"function","title":"Telegram.Bot.Utils.get_from_username/1","doc":"Get the \"from.user\" field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_from_username/1"},{"type":"function","title":"Telegram.Bot.Utils.get_sent_date/1","doc":"Get the sent \"date\" field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_sent_date/1"},{"type":"function","title":"Telegram.Bot.Utils.name/2","doc":"Process name atom maker.\nComposed by Supervisor/GenServer/_ module name + bot behaviour module name","ref":"Telegram.Bot.Utils.html#name/2"},{"type":"behaviour","title":"Telegram.ChatBot","doc":"Telegram Chat Bot behaviour.\n\nThe difference with `Telegram.Bot` behaviour is that the `Telegram.ChatBot` is \"statefull\" per chat_id,\n(see `chat_state` argument).\n\nGiven that every \"conversation\" is associated with a long running process is up to you to consider\na session timeout in your bot state machine design. If you don't you will saturate the max_bot_concurrency\ncapacity and then your bot won't accept any new conversation.\nFor this you can leverage the underlying gen_server timeout including the timeout in the return value\nof the `c:init/1` or `c:handle_update/3` callbacks or, if you need a more complex behaviour, via explicit\ntimers in you bot.","ref":"Telegram.ChatBot.html"},{"type":"behaviour","title":"Example - Telegram.ChatBot","doc":"```elixir\ndefmodule HelloBot do\n  use Telegram.ChatBot\n\n  @session_ttl 60 * 1_000\n\n  @impl Telegram.ChatBot\n  def init(_chat) do\n    count_state = 0\n    {:ok, count_state, @session_ttl}\n  end\n\n  @impl Telegram.ChatBot\n  def handle_update(%{\"message\" => %{\"chat\" => %{\"id\" => chat_id}}}, token, count_state) do\n    count_state = count_state + 1\n\n    Telegram.Api.request(token, \"sendMessage\",\n      chat_id: chat_id,\n      text: \"Hey! You sent me #{count_state} messages\"\n    )\n\n    {:ok, count_state, @session_ttl}\n  end\n\n  def handle_update(update, _token, count_state) do\n    # ignore unknown updates\n\n    {:ok, count_state, @session_ttl}\n  end\n\n  @impl Telegram.ChatBot\n  def handle_info(msg, _token, _chat_id, count_state) do\n    # direct message processing\n\n    {:ok, count_state}\n  end\n\n  @impl Telegram.ChatBot\n  def handle_timeout(token, chat_id, count_state) do\n    Telegram.Api.request(token, \"sendMessage\",\n      chat_id: chat_id,\n      text: \"See you!\"\n    )\n\n    {:stop, count_state}\n  end\nend\n```","ref":"Telegram.ChatBot.html#module-example"},{"type":"callback","title":"Telegram.ChatBot.handle_info/4","doc":"On handle_info callback.\n\nCan be used to implement bots that act on scheduled events (using `Process.send/3` and `Process.send_after/4`) or to interact via direct message to a a specific chat session (using `lookup/2`).\n\nThis callback is optional.\nIf one is not implemented, the received message will be logged.","ref":"Telegram.ChatBot.html#c:handle_info/4"},{"type":"callback","title":"Telegram.ChatBot.handle_resume/1","doc":"On resume callback.\n\nThis callback is optional.\nA default implementation is injected with \"use Telegram.ChatBot\", it just returns the received state.\n\nNote: a resume/3 function is available on every ChatBot, `MyChatBot.resume(token, chat_id, state)`.","ref":"Telegram.ChatBot.html#c:handle_resume/1"},{"type":"callback","title":"Telegram.ChatBot.handle_timeout/3","doc":"On timeout callback.\n\nThis callback is optional.\nA default implementation is injected with \"use Telegram.ChatBot\", it just stops the bot.","ref":"Telegram.ChatBot.html#c:handle_timeout/3"},{"type":"callback","title":"Telegram.ChatBot.handle_update/3","doc":"Receives the telegram update event and the \"current\" chat_state.\nReturn the \"updated\" chat_state.","ref":"Telegram.ChatBot.html#c:handle_update/3"},{"type":"callback","title":"Telegram.ChatBot.init/1","doc":"Invoked once when the chat starts.\nReturn the initial chat_state.","ref":"Telegram.ChatBot.html#c:init/1"},{"type":"function","title":"Telegram.ChatBot.lookup/2","doc":"Lookup the pid of a specific chat session.\n\nIt is up to the user to define and keep a mapping between\nthe business logic specific session identifier and the telegram chat_id.","ref":"Telegram.ChatBot.html#lookup/2"},{"type":"type","title":"Telegram.ChatBot.chat/0","doc":"","ref":"Telegram.ChatBot.html#t:chat/0"},{"type":"type","title":"Telegram.ChatBot.chat_state/0","doc":"","ref":"Telegram.ChatBot.html#t:chat_state/0"},{"type":"type","title":"Telegram.ChatBot.t/0","doc":"","ref":"Telegram.ChatBot.html#t:t/0"},{"type":"module","title":"Telegram.Poller","doc":"Telegram poller supervisor.","ref":"Telegram.Poller.html"},{"type":"module","title":"Usage - Telegram.Poller","doc":"In you app supervisor tree:\n\n```elixir\nbot_config = [\n  token: Application.fetch_env!(:my_app, :token_counter_bot),\n  max_bot_concurrency: Application.fetch_env!(:my_app, :max_bot_concurrency)\n]\n\nchildren = [\n  {Telegram.Poller, bots: [{MyApp.Bot, bot_config}]}\n  ...\n]\n\nopts = [strategy: :one_for_one, name: MyApp.Supervisor]\nSupervisor.start_link(children, opts)\n```","ref":"Telegram.Poller.html#module-usage"},{"type":"function","title":"Telegram.Poller.assert_tesla_adapter_config/0","doc":"","ref":"Telegram.Poller.html#assert_tesla_adapter_config/0"},{"type":"function","title":"Telegram.Poller.child_spec/1","doc":"Returns a specification to start this module under a supervisor.\n\nSee `Supervisor`.","ref":"Telegram.Poller.html#child_spec/1"},{"type":"function","title":"Telegram.Poller.start_link/1","doc":"","ref":"Telegram.Poller.html#start_link/1"},{"type":"module","title":"Telegram.Types","doc":"Telegram types","ref":"Telegram.Types.html"},{"type":"type","title":"Telegram.Types.bot_opts/0","doc":"","ref":"Telegram.Types.html#t:bot_opts/0"},{"type":"type","title":"Telegram.Types.bot_routing/0","doc":"","ref":"Telegram.Types.html#t:bot_routing/0"},{"type":"type","title":"Telegram.Types.bot_spec/0","doc":"","ref":"Telegram.Types.html#t:bot_spec/0"},{"type":"type","title":"Telegram.Types.max_bot_concurrency/0","doc":"","ref":"Telegram.Types.html#t:max_bot_concurrency/0"},{"type":"type","title":"Telegram.Types.method/0","doc":"","ref":"Telegram.Types.html#t:method/0"},{"type":"type","title":"Telegram.Types.token/0","doc":"","ref":"Telegram.Types.html#t:token/0"},{"type":"type","title":"Telegram.Types.update/0","doc":"","ref":"Telegram.Types.html#t:update/0"},{"type":"module","title":"Telegram.WebServer.Bandit","doc":"Bandit child specification for `Plug` compatible webserver.\n\nSee `Telegram.Webhook`.","ref":"Telegram.WebServer.Bandit.html"},{"type":"function","title":"Telegram.WebServer.Bandit.child_spec/2","doc":"","ref":"Telegram.WebServer.Bandit.html#child_spec/2"},{"type":"module","title":"Telegram.WebServer.Cowboy","doc":"Cowboy child specification for `Plug` compatible webserver.\n\nSee `Telegram.Webhook`.","ref":"Telegram.WebServer.Cowboy.html"},{"type":"function","title":"Telegram.WebServer.Cowboy.child_spec/2","doc":"","ref":"Telegram.WebServer.Cowboy.html#child_spec/2"},{"type":"module","title":"Telegram.Webhook","doc":"Telegram Webhook supervisor.","ref":"Telegram.Webhook.html"},{"type":"module","title":"Usage - Telegram.Webhook","doc":"#","ref":"Telegram.Webhook.html#module-usage"},{"type":"module","title":"WebServer adapter - Telegram.Webhook","doc":"Two `Plug` compatible webserver are supported:\n\n- `Telegram.WebServer.Bandit`: use `Bandit`\n- `Telegram.WebServer.Cowboy` (default): use `Plug.Cowboy`\n\nYou should configure the desired webserver adapter in you app configuration:\n\n```elixir\nconfig :telegram,\n  webserver: Telegram.WebServer.Bandit\n\n# OR\n\nconfig :telegram,\n  webserver: Telegram.WebServer.Cowboy\n```\n\nand include in you dependencies one of:\n\n```elixir\n{:plug_cowboy, \"~> 2.5\"}\n\n# OR\n\n{:bandit, \"~> 1.0-pre\"}\n```\n\n#","ref":"Telegram.Webhook.html#module-webserver-adapter"},{"type":"module","title":"Supervision tree - Telegram.Webhook","doc":"In you app supervision tree:\n\n```elixir\nwebhook_config = [\n  host: \"myapp.public-domain.com\",\n  port: 443,\n  local_port: 4_000\n]\n\nbot_config = [\n  token: Application.fetch_env!(:my_app, :token_counter_bot),\n  max_bot_concurrency: Application.fetch_env!(:my_app, :max_bot_concurrency)\n]\n\nchildren = [\n  {Telegram.Webhook, config: webhook_config, bots: [{MyApp.Bot, bot_config}]}\n  ...\n]\n\nopts = [strategy: :one_for_one, name: MyApp.Supervisor]\nSupervisor.start_link(children, opts)\n```","ref":"Telegram.Webhook.html#module-supervision-tree"},{"type":"module","title":"Ref - Telegram.Webhook","doc":"- https://core.telegram.org/bots/api#setwebhook\n- https://core.telegram.org/bots/webhooks","ref":"Telegram.Webhook.html#module-ref"},{"type":"function","title":"Telegram.Webhook.child_spec/1","doc":"Returns a specification to start this module under a supervisor.\n\nSee `Supervisor`.","ref":"Telegram.Webhook.html#child_spec/1"},{"type":"function","title":"Telegram.Webhook.start_link/1","doc":"","ref":"Telegram.Webhook.html#start_link/1"},{"type":"type","title":"Telegram.Webhook.config/0","doc":"Webhook configuration.\n\n- `host`: (reverse proxy) hostname of the HTTPS webhook url (required)\n- `port`: (reverse proxy) port of the HTTPS webhook url (optional, default: 443)\n- `local_port`: (backend) port of the application HTTP web server (optional, default: 4000)\n- `max_connections`: maximum allowed number of simultaneous connections to the webhook for update delivery (optional, defaults 40)","ref":"Telegram.Webhook.html#t:config/0"},{"type":"extras","title":"Telegram","doc":"# Telegram\n\n![CI](https://github.com/visciang/telegram/workflows/CI/badge.svg) [![Docs](https://img.shields.io/badge/docs-latest-green.svg)](https://visciang.github.io/telegram/readme.html) [![Coverage Status](https://coveralls.io/repos/github/visciang/telegram/badge.svg?branch=master)](https://coveralls.io/github/visciang/telegram?branch=master)\n\nTelegram library for the Elixir language.\n\nIt provides:\n- an inteface to the Telegram Bot HTTP-based APIs (`Telegram.Api`) \n- a couple of bot behaviours to define you bots (`Telegram.Bot`, `Telegram.ChatBot`)\n- two bot runners (`Telegram.Poller`, `Telegram.Webhook`)","ref":"readme.html"},{"type":"extras","title":"Installation - Telegram","doc":"The package can be installed by adding `telegram` to your list of dependencies in `mix.exs`:\n\n```elixir\ndef deps do\n  [\n    {:telegram, github: \"visciang/telegram\", tag: \"xxx\"}\n  ]\nend\n```\n\n# Telegram Bot API\n\nThis module expose a light layer over the Telegram Bot API HTTP-based interface,\nit does not expose any \"(data)binding\" over the HTTP interface and tries to abstract\naway only the boilerplate for building / sending / serializing the API requests.\n\nCompared to a full data-binded interface it could result less \"typed frendly\" but it will\nwork with any version of the Bot API, hopefully without updates or incompatibily\nwith new Bot API versions (as much as they remain backward compatible).\n\n\nReferences:\n* [API specification](https://core.telegram.org/bots/api)\n* [Bot intro for developers](https://core.telegram.org/bots)\n\nGiven the token of your Bot you can issue any request using:\n* method: Telegram API method name (ex. \"getMe\", \"sendMessage\")\n* options: Telegram API method specific parameters (you can use Elixir's native types)","ref":"readme.html#installation"},{"type":"extras","title":"Examples: - Telegram","doc":"Given the bot token (something like):\n\n```elixir\ntoken = \"123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11\"\n```\n\n### [getMe](https://core.telegram.org/bots/api#getme)\n\n```elixir\nTelegram.Api.request(token, \"getMe\")\n\n{:ok, %{\"first_name\" => \"Abc\", \"id\" => 1234567, \"is_bot\" => true, \"username\" => \"ABC\"}}\n```\n\n### [sendMessage](https://core.telegram.org/bots/api#sendmessage)\n\n```elixir\nTelegram.Api.request(token, \"sendMessage\", chat_id: 876532, text: \"Hello! .. silently\", disable_notification: true)\n\n{:ok,\n  %{\"chat\" => %{\"first_name\" => \"Firstname\",\n      \"id\" => 208255328,\n      \"last_name\" => \"Lastname\",\n      \"type\" => \"private\",\n      \"username\" => \"xxxx\"},\n    \"date\" => 1505118722,\n    \"from\" => %{\"first_name\" => \"Yyy\",\n      \"id\" => 234027650,\n      \"is_bot\" => true,\n      \"username\" => \"yyy\"},\n    \"message_id\" => 1402,\n    \"text\" => \"Hello! .. silently\"}}\n```\n\n### [getUpdates](https://core.telegram.org/bots/api#getupdates)\n\n```elixir\nTelegram.Api.request(token, \"getUpdates\", offset: -1, timeout: 30)\n\n{:ok,\n  [%{\"message\" => %{\"chat\" => %{\"first_name\" => \"Firstname\",\n        \"id\" => 208255328,\n        \"last_name\" => \"Lastname\",\n        \"type\" => \"private\",\n        \"username\" => \"xxxx\"},\n      \"date\" => 1505118098,\n      \"from\" => %{\"first_name\" => \"Firstname\",\n        \"id\" => 208255328,\n        \"is_bot\" => false,\n        \"language_code\" => \"en-IT\",\n        \"last_name\" => \"Lastname\",\n        \"username\" => \"xxxx\"},\n      \"message_id\" => 1401,\n      \"text\" => \"Hello!\"},\n    \"update_id\" => 129745295}]}\n```","ref":"readme.html#examples"},{"type":"extras","title":"Sending files - Telegram","doc":"If an API parameter has a `InputFile` type and you want to send a local file,\nfor example a photo stored at \"/tmp/photo.jpg\", just wrap the parameter\nvalue in a `{:file, \"/tmp/photo.jpg\"}` tuple. If the file content is in memory\nwrap it in a `{:file_content, data, \"photo.jpg\"}` tuple.\n\n### [sendPhoto](https://core.telegram.org/bots/api#sendphoto)\n\n```elixir\nTelegram.Api.request(token, \"sendPhoto\", chat_id: 876532, photo: {:file, \"/tmp/photo.jpg\"})\nTelegram.Api.request(token, \"sendPhoto\", chat_id: 876532, photo: {:file_content, photo, \"photo.jpg\"})\n```","ref":"readme.html#sending-files"},{"type":"extras","title":"Downloading files - Telegram","doc":"To download a file from the telegram server you need a `file_path` pointer to the file.\nWith that you can download the file via `Telegram.Api.file`.\n\n```elixir\n{:ok, res} = Telegram.Api.request(token, \"sendPhoto\", chat_id: 12345, photo: {:file, \"example/photo.jpg\"})\n# pick the 'file_obj' with the desired resolution\n[file_obj | _] = res[\"photo\"]\n# get the 'file_id'\nfile_id = file_obj[\"file_id\"]\n```\n\n### [getFile](https://core.telegram.org/bots/api#getfile)\n\n```elixir\n{:ok, %{\"file_path\" => file_path}} = Telegram.Api.request(token, \"getFile\", file_id: file_id)\n{:ok, file} = Telegram.Api.file(token, file_path)\n```","ref":"readme.html#downloading-files"},{"type":"extras","title":"JSON-serialized object parameters - Telegram","doc":"If an API parameter has a non primitive scalar type it is explicitly pointed out as \"A JSON-serialized object\"\n(ie `InlineKeyboardMarkup`, `ReplyKeyboardMarkup`, etc).\nIn this case you can wrap the parameter value in a `{:json, value}` tuple.\n\n### [sendMessage](https://core.telegram.org/bots/api#sendmessage) with keyboard\n\n```elixir\nkeyboard = [\n  [\"A0\", \"A1\"],\n  [\"B0\", \"B1\", \"B2\"]\n]\nkeyboard_markup = %{one_time_keyboard: true, keyboard: keyboard}\nTelegram.Api.request(token, \"sendMessage\", chat_id: 876532, text: \"Here a keyboard!\", reply_markup: {:json, keyboard_markup})\n```\n\n# Telegram Bot","ref":"readme.html#json-serialized-object-parameters"},{"type":"extras","title":"Quick start - Telegram","doc":"Check the examples under `example/example_*.exs`.\nYou can run them as a `Mix` self-contained script.\n\n```shell\nBOT_TOKEN=\"...\" example/example_chatbot.exs\n```","ref":"readme.html#quick-start"},{"type":"extras","title":"Bot updates processing - Telegram","doc":"The Telegram platform supports two ways of processing bot updates, `getUpdates` and `setWebhook`.\n`getUpdates` is a pull mechanism, `setWebhook` is a push mechanism. (ref: [bots webhook](https://core.telegram.org/bots/webhooks))\n\nThis library currently implements both models via two supervisors.\n\n#","ref":"readme.html#bot-updates-processing"},{"type":"extras","title":"Poller - Telegram","doc":"This mode can be used in a dev environment or if your bot doesn't need to \"scale\". Being in pull it works well behind a firewall (or behind a home internet router).\nRefer to the `Telegram.Poller` module docs for more info.\n\n\n##","ref":"readme.html#poller"},{"type":"extras","title":"Telegram Client Config - Telegram","doc":"The Telegram HTTP Client is based on `Tesla`.\n\nThe `Tesla.Adapter` and options should be configured via the `[:tesla, :adapter]` application environment key.\n(ref. https://hexdocs.pm/tesla/readme.html#adapters)\n\nFor example, a good default could be:\n\n```elixir\nconfig :tesla, adapter: {Tesla.Adapter.Hackney, [recv_timeout: 40_000]}\n```\n\na dependency should be added accordingly in your `mix.exs`:\n\n```elixir\n defp deps do\n    [\n      {:telegram, github: \"visciang/telegram\", tag: \"xxx\"},\n      {:hackney, \"~> 1.18\"},\n      # ...\n    ]\n  end\n```\n\n#","ref":"readme.html#telegram-client-config"},{"type":"extras","title":"Webhook - Telegram","doc":"This mode interfaces with the Telegram servers via a webhook, best for production use.\nThe app is meant to be served over HTTP, a reverse proxy should be placed in front of it, facing the public network over HTTPS.\n\nIt's possible to use two `Plug` compatible webserver: `Bandit` and `Plug.Cowboy`.\n\nRefer to the `Telegram.Webhook` module docs for more info.","ref":"readme.html#webhook"},{"type":"extras","title":"Dispatch model - Telegram","doc":"We can define stateless / stateful bot.\n\n* A stateless Bot has no memory of previous conversations, it just receives updates, process them and so on.\n\n* A stateful Bot instead can remember what happened in the past.\nThe state here refer to a specific chat, a conversation (chat_id) between a user and a bot \"instance\".","ref":"readme.html#dispatch-model"},{"type":"extras","title":"Bot behaviours - Telegram","doc":"* `Telegram.Bot`: works with the **stateless async** dispatch model\n* `Telegram.ChatBot`: works with the **stateful chat** dispatch model","ref":"readme.html#bot-behaviours"},{"type":"extras","title":"Logging - Telegram","doc":"The library attaches two metadata fields to the internal logs: [:bot, :chat_id].\nIf your app runs more that one bot these fields can be included in your logs (ref. to the Logger config)\nto clearly identify and \"trace\" every bot's message flow.\n\n# Sample app\n\nA chat_bot app, deployed to Gigalixir PaaS and served in webhook mode: https://github.com/visciang/telegram_example","ref":"readme.html#logging"}],"content_type":"text/markdown"}