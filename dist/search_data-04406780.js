searchData={"items":[{"type":"module","title":"Telegram.Api","doc":"Telegram Bot API - HTTP-based interface","ref":"Telegram.Api.html"},{"type":"function","title":"Telegram.Api.file/2","doc":"Download a file.\n\nReference: [BOT Api](https://core.telegram.org/bots/api#file)\n\nExample:\n\n```elixir\n# send a photo\n{:ok, res} = Telegram.Api.request(token, \"sendPhoto\", chat_id: 12345, photo: {:file, \"example/photo.jpg\"})\n# pick the 'file_obj' with the desired resolution\n[file_obj | _] = res[\"photo\"]\n# get the 'file_id'\nfile_id = file_obj[\"file_id\"]\n\n# obtain the 'file_path' to download the file identified by 'file_id'\n{:ok, %{\"file_path\" => file_path}} = Telegram.Api.request(token, \"getFile\", file_id: file_id)\n{:ok, file} = Telegram.Api.file(token, file_path)\n```","ref":"Telegram.Api.html#file/2"},{"type":"function","title":"Telegram.Api.request/3","doc":"Send a Telegram Bot API request.\n\nThe request `parameters` map to the bots API parameters.\n\n- `Integer String Boolean Float`: Elixir native data type\n- `JSON-serialized`: `{:json, _}` tuple\n- `InputFile`: `{:file, _}` or `{:file_content, _, _}` tuple\n\nReference: [BOT Api](https://core.telegram.org/bots/api)","ref":"Telegram.Api.html#request/3"},{"type":"type","title":"Telegram.Api.parameter_name/0","doc":"","ref":"Telegram.Api.html#t:parameter_name/0"},{"type":"type","title":"Telegram.Api.parameter_value/0","doc":"","ref":"Telegram.Api.html#t:parameter_value/0"},{"type":"type","title":"Telegram.Api.parameters/0","doc":"","ref":"Telegram.Api.html#t:parameters/0"},{"type":"type","title":"Telegram.Api.request_result/0","doc":"","ref":"Telegram.Api.html#t:request_result/0"},{"type":"behaviour","title":"Telegram.Bot","doc":"Telegram Bot behaviour.","ref":"Telegram.Bot.html"},{"type":"behaviour","title":"Example - Telegram.Bot","doc":"```elixir\ndefmodule HelloBot do\n  use Telegram.Bot\n\n  @impl Telegram.Bot\n  def handle_update(\n    %{\"message\" => %{\"text\" => \"/hello\", \"chat\" => %{\"id\" => chat_id, \"username\" => username}, \"message_id\" => message_id}},\n    token\n  ) do\n    Telegram.Api.request(token, \"sendMessage\",\n      chat_id: chat_id,\n      reply_to_message_id: message_id,\n      text: \"Hello #{username}!\"\n    )\n  end\n\n  def handle_update(_update, _token) do\n    # ignore unknown updates\n\n    :ok\n  end\nend\n```","ref":"Telegram.Bot.html#module-example"},{"type":"callback","title":"Telegram.Bot.handle_update/2","doc":"The function receives the telegram update event.","ref":"Telegram.Bot.html#c:handle_update/2"},{"type":"behaviour","title":"Telegram.Bot.Dispatch","doc":"Dispatch behaviour","ref":"Telegram.Bot.Dispatch.html"},{"type":"callback","title":"Telegram.Bot.Dispatch.dispatch_update/2","doc":"","ref":"Telegram.Bot.Dispatch.html#c:dispatch_update/2"},{"type":"type","title":"Telegram.Bot.Dispatch.t/0","doc":"","ref":"Telegram.Bot.Dispatch.html#t:t/0"},{"type":"module","title":"Telegram.Bot.Utils","doc":"Bot utilities","ref":"Telegram.Bot.Utils.html"},{"type":"function","title":"Telegram.Bot.Utils.get_from_username/1","doc":"Get the \"from.user\" field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_from_username/1"},{"type":"function","title":"Telegram.Bot.Utils.get_sent_date/1","doc":"Get the sent \"date\" field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_sent_date/1"},{"type":"function","title":"Telegram.Bot.Utils.name/2","doc":"Process name atom maker.\nComposed by Supervisor/GenServer/_ module name + bot behaviour module name","ref":"Telegram.Bot.Utils.html#name/2"},{"type":"behaviour","title":"Telegram.ChatBot","doc":"Telegram Chat Bot behaviour.\n\nThe `Telegram.ChatBot` module provides a stateful chatbot mechanism that manages bot instances\non a per-chat basis (`chat_id`). Unlike the `Telegram.Bot` behavior, which is stateless,\neach conversation in `Telegram.ChatBot` is tied to a unique `chat_state`.\n\nThe `c:get_chat/2` callback is responsible for routing each incoming update to the correct\nchat session by returning the chat's identifier. If the chat is not yet recognized,\na new bot instance will automatically be created for that chat.\n\nSince each conversation is handled by a long-running process, it's crucial to manage session\ntimeouts carefully. Without implementing timeouts, your bot may hit the `max_bot_concurrency` limit,\npreventing it from handling new conversations. To prevent this, you can utilize the underlying\n`:gen_server` timeout mechanism by specifying timeouts in the return values of the `c:init/1` or\n`c:handle_update/3` callbacks. Alternatively, for more complex scenarios, you can manage explicit\ntimers in your bot's logic.","ref":"Telegram.ChatBot.html"},{"type":"behaviour","title":"Example - Telegram.ChatBot","doc":"```elixir\ndefmodule HelloBot do\n  use Telegram.ChatBot\n\n  # Session timeout set to 60 seconds\n  @session_ttl 60 * 1_000\n\n  @impl Telegram.ChatBot\n  def init(_chat) do\n    # Initialize state with a message counter set to 0\n    count_state = 0\n    {:ok, count_state, @session_ttl}\n  end\n\n  @impl Telegram.ChatBot\n  def handle_update(%{\"message\" => %{\"chat\" => %{\"id\" => chat_id}}}, token, count_state) do\n    # Increment the message count\n    count_state = count_state + 1\n\n    Telegram.Api.request(token, \"sendMessage\",\n      chat_id: chat_id,\n      text: \"Hey! You sent me #{count_state} messages\"\n    )\n\n    {:ok, count_state, @session_ttl}\n  end\n\n  def handle_update(update, _token, count_state) do\n    # Ignore unknown updates and maintain the current state\n\n    {:ok, count_state, @session_ttl}\n  end\n\n  @impl Telegram.ChatBot\n  def handle_info(msg, _token, _chat_id, count_state) do\n    # Handle direct erlang messages, if needed\n\n    {:ok, count_state}\n  end\n\n  @impl Telegram.ChatBot\n  def handle_timeout(token, chat_id, count_state) do\n    # Send a \"goodbye\" message upon session timeout\n    Telegram.Api.request(token, \"sendMessage\",\n      chat_id: chat_id,\n      text: \"See you!\"\n    )\n\n    {:stop, count_state}\n  end\nend\n```","ref":"Telegram.ChatBot.html#module-example"},{"type":"callback","title":"Telegram.ChatBot.get_chat/2","doc":"Allows a chatbot to customize how incoming updates are processed.\n\nThis function receives an update and either returns the unique chat identifier\nassociated with it or instructs the bot to ignore the update.","ref":"Telegram.ChatBot.html#c:get_chat/2"},{"type":"callback","title":"Parameters: - Telegram.ChatBot.get_chat/2","doc":"- `update_type`: is a string representing the type of update received. For example:\n  - `message`: For new messages.\n  - `edited_message`: For edited messages.\n  - `inline_query`: For inline queries.\n- `update`: the update object received, containing the data associated with the `update_type`.\n  The object structure depends on the type of update:\n  - For `message` and `edited_message` updates, the object is of type [`Message`](https://core.telegram.org/bots/api#message),\n    which contains fields such as text, sender, and chat.\n  - For `inline_query` updates, the object is of type [`InlineQuery`](https://core.telegram.org/bots/api#inlinequery), containing fields like query and from.\n\nRefer to the official Telegram Bot API [documentation](https://core.telegram.org/bots/api#update)\nfor a complete list of update types.","ref":"Telegram.ChatBot.html#c:get_chat/2-parameters"},{"type":"callback","title":"Return values: - Telegram.ChatBot.get_chat/2","doc":"- Returning `{:ok, %Telegram.ChatBot.Chat{id: id, metadata: %{}}}` will trigger\n  the bot to spin up a new instance, which will manage the update as a full chat session.\n  The instance will be uniquely identified by the return `id` and\n  `c:init/1` will be called with the returned `t:Telegram.ChatBot.Chat.t/0` struct.\n- Returning `:ignore` will cause the update to be disregarded entirely.\n\nThis callback is **optional**.\nIf not implemented, the bot will dispatch updates of type [`Message`](https://core.telegram.org/bots/api#message).","ref":"Telegram.ChatBot.html#c:get_chat/2-return-values"},{"type":"callback","title":"Telegram.ChatBot.handle_info/4","doc":"Invoked to handle arbitrary erlang messages (e.g., scheduled events or direct messages).\n\nThis callback can be used for:\n- Scheduled Events: handle messages triggered by Process.send/3 or Process.send_after/4.\n- Direct Interactions: respond to direct messages sent to a specific chat session retrieved via `lookup/2`.","ref":"Telegram.ChatBot.html#c:handle_info/4"},{"type":"callback","title":"Parameters: - Telegram.ChatBot.handle_info/4","doc":"- `msg`: the message received.\n- `token`: the bot's authentication token, used to make API requests.\n- `chat_id`: the ID of the chat session associated with the message.\n- `chat_state`: the current state of the chat session.","ref":"Telegram.ChatBot.html#c:handle_info/4-parameters"},{"type":"callback","title":"Return values: - Telegram.ChatBot.handle_info/4","doc":"- `{:ok, next_chat_state}`: updates the session with a new `next_chat_state`.\n- `{:ok, next_chat_state, timeout}`: updates the `next_chat_state` and sets a new `timeout`.\n- `{:stop, next_chat_state}`: terminates the session and returns the final `chat_state`.\n\nThis callback is **optional**.\nIf not implemented, any received message will be logged by default.","ref":"Telegram.ChatBot.html#c:handle_info/4-return-values"},{"type":"callback","title":"Telegram.ChatBot.handle_resume/1","doc":"Invoked when a chat session is resumed.\n\nIf implemented, this function allows custom logic when resuming a session, for example,\nupdating the state or setting a new timeout.\n\nNote: you can manually resume a session by calling `MyChatBot.resume(token, chat_id, state)`.","ref":"Telegram.ChatBot.html#c:handle_resume/1"},{"type":"callback","title":"Return values - Telegram.ChatBot.handle_resume/1","doc":"- `{:ok, next_chat_state}`: resumes the session with the provided `next_chat_state`.\n- `{:ok, next_chat_state, timeout}`: resumes the session with the `next_chat_state` and sets a new `timeout`.\n\nThe `timeout` can be used to schedule actions after a specific period of inactivity.","ref":"Telegram.ChatBot.html#c:handle_resume/1-return-values"},{"type":"callback","title":"Telegram.ChatBot.handle_timeout/3","doc":"Callback invoked when a session times out.","ref":"Telegram.ChatBot.html#c:handle_timeout/3"},{"type":"callback","title":"Parameters - Telegram.ChatBot.handle_timeout/3","doc":"- `token`: the bot's authentication token, used for making API requests.\n- `chat_id`: the ID of the chat where the session timed out.\n- `chat_state`: the current state of the chat session at the time of the timeout.","ref":"Telegram.ChatBot.html#c:handle_timeout/3-parameters"},{"type":"callback","title":"Return Values: - Telegram.ChatBot.handle_timeout/3","doc":"- `{:ok, next_chat_state}`: keeps the session alive with an updated `next_chat_state`.\n- `{:ok, next_chat_state, timeout}`: updates the `next_chat_state` and sets a new `timeout`.\n- `{:stop, next_chat_state}`: terminates the session and finalizes the `chat_state`.\n\nThis callback is **optional**.\nIf not implemented, the bot will stops when a timeout occurs.","ref":"Telegram.ChatBot.html#c:handle_timeout/3-return-values"},{"type":"callback","title":"Telegram.ChatBot.handle_update/3","doc":"Handles incoming Telegram update events and processes them based on the current `chat_state`.","ref":"Telegram.ChatBot.html#c:handle_update/3"},{"type":"callback","title":"Parameters: - Telegram.ChatBot.handle_update/3","doc":"- `update`: the incoming Telegram [update](https://core.telegram.org/bots/api#update) event (e.g., a message, an inline query).\n- `token`: the bot's authentication token, used to make API requests.\n- `chat_state`: the current state of the chat session.","ref":"Telegram.ChatBot.html#c:handle_update/3-parameters"},{"type":"callback","title":"Return values: - Telegram.ChatBot.handle_update/3","doc":"- `{:ok, next_chat_state}`: updates the chat session with the new `next_chat_state`.\n- `{:ok, next_chat_state, timeout}`: updates the `next_chat_state` and sets a new `timeout` for the session.\n- `{:stop, next_chat_state}`: terminates the chat session and returns the final `next_chat_state`.\n\nThe `timeout` option can be used to define how long the bot will wait for the next event before triggering a timeout.","ref":"Telegram.ChatBot.html#c:handle_update/3-return-values"},{"type":"callback","title":"Telegram.ChatBot.init/1","doc":"Invoked when a chat session is first initialized. Returns the initial `chat_state` for the session.","ref":"Telegram.ChatBot.html#c:init/1"},{"type":"callback","title":"Parameters: - Telegram.ChatBot.init/1","doc":"- `chat`: the `t:Telegram.ChatBot.Chat.t/0` struct returned by `c:get_chat/2`.","ref":"Telegram.ChatBot.html#c:init/1-parameters"},{"type":"callback","title":"Return values - Telegram.ChatBot.init/1","doc":"- `{:ok, initial_state}`: initializes the session with the provided `initial_state`.\n- `{:ok, initial_state, timeout}`: initializes the session with the provided `initial_state`, and sets a timeout for the session.\n\nThe `timeout` can be used to schedule actions after a certain period of inactivity.","ref":"Telegram.ChatBot.html#c:init/1-return-values"},{"type":"function","title":"Telegram.ChatBot.lookup/2","doc":"Retrieves the process ID (`pid`) of a specific chat session.\n\nThis function allows you to look up the active process managing a particular chat session.\n\nNote: it is the user's responsibility to maintain and manage the mapping between\nthe custom session identifier (specific to the business logic) and the Telegram `chat_id`.","ref":"Telegram.ChatBot.html#lookup/2"},{"type":"function","title":"Return values: - Telegram.ChatBot.lookup/2","doc":"- `{:ok, pid}`: successfully found the pid of the chat session.\n- `{:error, :not_found}`: no active session was found for the provided `chat_id`.","ref":"Telegram.ChatBot.html#lookup/2-return-values"},{"type":"type","title":"Telegram.ChatBot.chat/0","doc":"","ref":"Telegram.ChatBot.html#t:chat/0"},{"type":"type","title":"Telegram.ChatBot.chat_state/0","doc":"","ref":"Telegram.ChatBot.html#t:chat_state/0"},{"type":"type","title":"Telegram.ChatBot.t/0","doc":"","ref":"Telegram.ChatBot.html#t:t/0"},{"type":"module","title":"Telegram.ChatBot.Chat","doc":"A struct that represents a chat extracted from a Telegram update.\nCurrently the only required field is `id`, any other data you may want to pass to\n`c:Telegram.ChatBot.init/1` should be included under the `metadata` field.","ref":"Telegram.ChatBot.Chat.html"},{"type":"type","title":"Telegram.ChatBot.Chat.t/0","doc":"","ref":"Telegram.ChatBot.Chat.html#t:t/0"},{"type":"module","title":"Telegram.Poller","doc":"Telegram poller supervisor.","ref":"Telegram.Poller.html"},{"type":"module","title":"Usage - Telegram.Poller","doc":"In you app supervisor tree:\n\n```elixir\nbot_config = [\n  token: Application.fetch_env!(:my_app, :token_counter_bot),\n  max_bot_concurrency: Application.fetch_env!(:my_app, :max_bot_concurrency)\n]\n\nchildren = [\n  {Telegram.Poller, bots: [{MyApp.Bot, bot_config}]}\n  ...\n]\n\nopts = [strategy: :one_for_one, name: MyApp.Supervisor]\nSupervisor.start_link(children, opts)\n```","ref":"Telegram.Poller.html#module-usage"},{"type":"function","title":"Telegram.Poller.assert_tesla_adapter_config/0","doc":"","ref":"Telegram.Poller.html#assert_tesla_adapter_config/0"},{"type":"function","title":"Telegram.Poller.child_spec/1","doc":"Returns a specification to start this module under a supervisor.\n\nSee `Supervisor`.","ref":"Telegram.Poller.html#child_spec/1"},{"type":"function","title":"Telegram.Poller.start_link/1","doc":"","ref":"Telegram.Poller.html#start_link/1"},{"type":"module","title":"Telegram.Types","doc":"Telegram types","ref":"Telegram.Types.html"},{"type":"type","title":"Telegram.Types.bot_opts/0","doc":"","ref":"Telegram.Types.html#t:bot_opts/0"},{"type":"type","title":"Telegram.Types.bot_routing/0","doc":"","ref":"Telegram.Types.html#t:bot_routing/0"},{"type":"type","title":"Telegram.Types.bot_spec/0","doc":"","ref":"Telegram.Types.html#t:bot_spec/0"},{"type":"type","title":"Telegram.Types.max_bot_concurrency/0","doc":"","ref":"Telegram.Types.html#t:max_bot_concurrency/0"},{"type":"type","title":"Telegram.Types.method/0","doc":"","ref":"Telegram.Types.html#t:method/0"},{"type":"type","title":"Telegram.Types.token/0","doc":"","ref":"Telegram.Types.html#t:token/0"},{"type":"type","title":"Telegram.Types.update/0","doc":"","ref":"Telegram.Types.html#t:update/0"},{"type":"module","title":"Telegram.WebServer.Bandit","doc":"Bandit child specification for `Plug` compatible webserver.\n\nSee `Telegram.Webhook`.","ref":"Telegram.WebServer.Bandit.html"},{"type":"function","title":"Telegram.WebServer.Bandit.child_spec/2","doc":"","ref":"Telegram.WebServer.Bandit.html#child_spec/2"},{"type":"module","title":"Telegram.WebServer.Cowboy","doc":"Cowboy child specification for `Plug` compatible webserver.\n\nSee `Telegram.Webhook`.","ref":"Telegram.WebServer.Cowboy.html"},{"type":"function","title":"Telegram.WebServer.Cowboy.child_spec/2","doc":"","ref":"Telegram.WebServer.Cowboy.html#child_spec/2"},{"type":"module","title":"Telegram.Webhook","doc":"Telegram Webhook supervisor.\n\nThis modules can the used to start a webserver exposing a webhoook endpoint\nwhere the telegram server can push updates for your BOT.\nOn start the webhook address for the BOT is posted to the telegram server via the [`setWebHook`](https://core.telegram.org/bots/api#setwebhook) method.","ref":"Telegram.Webhook.html"},{"type":"module","title":"Usage - Telegram.Webhook","doc":"","ref":"Telegram.Webhook.html#module-usage"},{"type":"module","title":"WebServer adapter - Telegram.Webhook","doc":"Two `Plug` compatible webserver are supported:\n\n- `Telegram.WebServer.Bandit` (default): use `Bandit`\n- `Telegram.WebServer.Cowboy`: use `Plug.Cowboy`\n\nYou should configure the desired webserver adapter in you app configuration:\n\n```elixir\nconfig :telegram,\n  webserver: Telegram.WebServer.Bandit\n\n# OR\n\nconfig :telegram,\n  webserver: Telegram.WebServer.Cowboy\n```\n\nand include in you dependencies one of:\n\n```elixir\n{:plug_cowboy, \"~> 2.5\"}\n\n# OR\n\n{:bandit, \"~> 1.0\"}\n```","ref":"Telegram.Webhook.html#module-webserver-adapter"},{"type":"module","title":"Supervision tree - Telegram.Webhook","doc":"In you app supervision tree:\n\n```elixir\nwebhook_config = [\n  host: \"myapp.public-domain.com\",\n  port: 443,\n  local_port: 4_000\n]\n\nbot_config = [\n  token: Application.fetch_env!(:my_app, :token_counter_bot),\n  max_bot_concurrency: Application.fetch_env!(:my_app, :max_bot_concurrency)\n]\n\nchildren = [\n  {Telegram.Webhook, config: webhook_config, bots: [{MyApp.Bot, bot_config}]}\n  ...\n]\n\nopts = [strategy: :one_for_one, name: MyApp.Supervisor]\nSupervisor.start_link(children, opts)\n```","ref":"Telegram.Webhook.html#module-supervision-tree"},{"type":"module","title":"Ref - Telegram.Webhook","doc":"- https://core.telegram.org/bots/api#setwebhook\n- https://core.telegram.org/bots/webhooks\n\n# Direct Phoenix / Plug integration\n\nIf want to integrate the webhook in a Phoenix / Plug based application facing internet, you should (for each BOT):\n\n- add a POST route in your endpoints to receive the webhook updates and dispatch them to the BOT.\n- active the webhook mode posting a [`setWebHook`](https://core.telegram.org/bots/api#setwebhook) request to the telegram server.\n\nRefer to this module implementation as a guide line for the above.","ref":"Telegram.Webhook.html#module-ref"},{"type":"function","title":"Telegram.Webhook.child_spec/1","doc":"Returns a specification to start this module under a supervisor.\n\nSee `Supervisor`.","ref":"Telegram.Webhook.html#child_spec/1"},{"type":"function","title":"Telegram.Webhook.start_link/1","doc":"","ref":"Telegram.Webhook.html#start_link/1"},{"type":"type","title":"Telegram.Webhook.config/0","doc":"Webhook configuration.\n\n- `host`: (reverse proxy) hostname of the HTTPS webhook url (required)\n- `port`: (reverse proxy) port of the HTTPS webhook url (optional, default: 443)\n- `local_port`: (backend) port of the application HTTP web server (optional, default: 4000)\n- `max_connections`: maximum allowed number of simultaneous connections to the webhook for update delivery (optional, defaults 40)","ref":"Telegram.Webhook.html#t:config/0"},{"type":"extras","title":"Telegram","doc":"# Telegram\n\n[![.github/workflows/ci.yml](https://github.com/visciang/telegram/actions/workflows/ci.yml/badge.svg)](https://github.com/visciang/telegram/actions/workflows/ci.yml) [![Docs](https://img.shields.io/badge/docs-latest-green.svg)](https://visciang.github.io/telegram/readme.html) [![Coverage Status](https://coveralls.io/repos/github/visciang/telegram/badge.svg?branch=master)](https://coveralls.io/github/visciang/telegram?branch=master)\n\nTelegram library for the Elixir language.\n\nIt provides:\n- an inteface to the Telegram Bot HTTP-based APIs (`Telegram.Api`)\n- a couple of bot behaviours to define you bots (`Telegram.Bot`, `Telegram.ChatBot`)\n- two bot runners (`Telegram.Poller`, `Telegram.Webhook`)","ref":"readme.html"},{"type":"extras","title":"Installation - Telegram","doc":"The package can be installed by adding `telegram` to your list of dependencies in `mix.exs`:\n\n```elixir\ndef deps do\n  [\n    {:telegram, github: \"visciang/telegram\", tag: \"xxx\"}\n  ]\nend\n```\n\n# Telegram Bot API\n\nThis module expose a light layer over the Telegram Bot API HTTP-based interface,\nit does not expose any \"(data)binding\" over the HTTP interface and tries to abstract\naway only the boilerplate for building / sending / serializing the API requests.\n\nCompared to a full data-binded interface it could result less \"typed frendly\" but it will\nwork with any version of the Bot API, hopefully without updates or incompatibily\nwith new Bot API versions (as much as they remain backward compatible).\n\n\nReferences:\n* [API specification](https://core.telegram.org/bots/api)\n* [Bot intro for developers](https://core.telegram.org/bots)\n\nGiven the token of your Bot you can issue any request using:\n* method: Telegram API method name (ex. \"getMe\", \"sendMessage\")\n* options: Telegram API method specific parameters (you can use Elixir's native types)","ref":"readme.html#installation"},{"type":"extras","title":"Examples: - Telegram","doc":"Given the bot token (something like):\n\n```elixir\ntoken = \"123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11\"\n```\n\n### [getMe](https://core.telegram.org/bots/api#getme)\n\n```elixir\nTelegram.Api.request(token, \"getMe\")\n\n{:ok, %{\"first_name\" => \"Abc\", \"id\" => 1234567, \"is_bot\" => true, \"username\" => \"ABC\"}}\n```\n\n### [sendMessage](https://core.telegram.org/bots/api#sendmessage)\n\n```elixir\nTelegram.Api.request(token, \"sendMessage\", chat_id: 876532, text: \"Hello! .. silently\", disable_notification: true)\n\n{:ok,\n  %{\"chat\" => %{\"first_name\" => \"Firstname\",\n      \"id\" => 208255328,\n      \"last_name\" => \"Lastname\",\n      \"type\" => \"private\",\n      \"username\" => \"xxxx\"},\n    \"date\" => 1505118722,\n    \"from\" => %{\"first_name\" => \"Yyy\",\n      \"id\" => 234027650,\n      \"is_bot\" => true,\n      \"username\" => \"yyy\"},\n    \"message_id\" => 1402,\n    \"text\" => \"Hello! .. silently\"}}\n```\n\n### [getUpdates](https://core.telegram.org/bots/api#getupdates)\n\n```elixir\nTelegram.Api.request(token, \"getUpdates\", offset: -1, timeout: 30)\n\n{:ok,\n  [%{\"message\" => %{\"chat\" => %{\"first_name\" => \"Firstname\",\n        \"id\" => 208255328,\n        \"last_name\" => \"Lastname\",\n        \"type\" => \"private\",\n        \"username\" => \"xxxx\"},\n      \"date\" => 1505118098,\n      \"from\" => %{\"first_name\" => \"Firstname\",\n        \"id\" => 208255328,\n        \"is_bot\" => false,\n        \"language_code\" => \"en-IT\",\n        \"last_name\" => \"Lastname\",\n        \"username\" => \"xxxx\"},\n      \"message_id\" => 1401,\n      \"text\" => \"Hello!\"},\n    \"update_id\" => 129745295}]}\n```","ref":"readme.html#examples"},{"type":"extras","title":"Sending files - Telegram","doc":"If an API parameter has a `InputFile` type and you want to send a local file,\nfor example a photo stored at \"/tmp/photo.jpg\", just wrap the parameter\nvalue in a `{:file, \"/tmp/photo.jpg\"}` tuple. If the file content is in memory\nwrap it in a `{:file_content, data, \"photo.jpg\"}` tuple.\n\n### [sendPhoto](https://core.telegram.org/bots/api#sendphoto)\n\n```elixir\nTelegram.Api.request(token, \"sendPhoto\", chat_id: 876532, photo: {:file, \"/tmp/photo.jpg\"})\nTelegram.Api.request(token, \"sendPhoto\", chat_id: 876532, photo: {:file_content, photo, \"photo.jpg\"})\n```","ref":"readme.html#sending-files"},{"type":"extras","title":"Downloading files - Telegram","doc":"To download a file from the telegram server you need a `file_path` pointer to the file.\nWith that you can download the file via `Telegram.Api.file`.\n\n```elixir\n{:ok, res} = Telegram.Api.request(token, \"sendPhoto\", chat_id: 12345, photo: {:file, \"example/photo.jpg\"})\n# pick the 'file_obj' with the desired resolution\n[file_obj | _] = res[\"photo\"]\n# get the 'file_id'\nfile_id = file_obj[\"file_id\"]\n```\n\n### [getFile](https://core.telegram.org/bots/api#getfile)\n\n```elixir\n{:ok, %{\"file_path\" => file_path}} = Telegram.Api.request(token, \"getFile\", file_id: file_id)\n{:ok, file} = Telegram.Api.file(token, file_path)\n```","ref":"readme.html#downloading-files"},{"type":"extras","title":"JSON-serialized object parameters - Telegram","doc":"If an API parameter has a non primitive scalar type it is explicitly pointed out as \"A JSON-serialized object\"\n(ie `InlineKeyboardMarkup`, `ReplyKeyboardMarkup`, etc).\nIn this case you can wrap the parameter value in a `{:json, value}` tuple.\n\n### [sendMessage](https://core.telegram.org/bots/api#sendmessage) with keyboard\n\n```elixir\nkeyboard = [\n  [\"A0\", \"A1\"],\n  [\"B0\", \"B1\", \"B2\"]\n]\nkeyboard_markup = %{one_time_keyboard: true, keyboard: keyboard}\nTelegram.Api.request(token, \"sendMessage\", chat_id: 876532, text: \"Here a keyboard!\", reply_markup: {:json, keyboard_markup})\n```\n\n# Telegram Bot","ref":"readme.html#json-serialized-object-parameters"},{"type":"extras","title":"Quick start - Telegram","doc":"Check the examples under `example/example_*.exs`.\nYou can run them as a `Mix` self-contained script.\n\n```shell\nBOT_TOKEN=\"...\" example/example_chatbot.exs\n```","ref":"readme.html#quick-start"},{"type":"extras","title":"Bot updates processing - Telegram","doc":"The Telegram platform supports two ways of processing bot updates, `getUpdates` and `setWebhook`.\n`getUpdates` is a pull mechanism, `setWebhook` is a push mechanism. (ref: [bots webhook](https://core.telegram.org/bots/webhooks))\n\nThis library currently implements both models via two supervisors.","ref":"readme.html#bot-updates-processing"},{"type":"extras","title":"Poller - Telegram","doc":"This mode can be used in a dev environment or if your bot doesn't need to \"scale\". Being in pull it works well behind a firewall (or behind a home internet router).\nRefer to the `Telegram.Poller` module docs for more info.\n\n\n#### Telegram Client Config\n\nThe Telegram HTTP Client is based on `Tesla`.\n\nThe `Tesla.Adapter` and options should be configured via the `[:tesla, :adapter]` application environment key.\n(ref. https://hexdocs.pm/tesla/readme.html#adapters)\n\nFor example, a good default could be:\n\n```elixir\nconfig :tesla, adapter: {Tesla.Adapter.Hackney, [recv_timeout: 40_000]}\n```\n\na dependency should be added accordingly in your `mix.exs`:\n\n```elixir\n defp deps do\n    [\n      {:telegram, github: \"visciang/telegram\", tag: \"xxx\"},\n      {:hackney, \"~> 1.18\"},\n      # ...\n    ]\n  end\n```","ref":"readme.html#poller"},{"type":"extras","title":"Webhook - Telegram","doc":"This mode interfaces with the Telegram servers via a webhook, best for production use.\nThe app is meant to be served over HTTP, a reverse proxy should be placed in front of it, facing the public network over HTTPS.\nIt's possible to use two `Plug` compatible webserver: `Bandit` and `Plug.Cowboy`.\n\nAlternatively, if you have a Phoenix / Plug based application facing internet, you can directly integrate the webhook.\n\nRefer to the `Telegram.Webhook` module docs for more info.","ref":"readme.html#webhook"},{"type":"extras","title":"Dispatch model - Telegram","doc":"We can define stateless / stateful bot.\n\n* A stateless Bot has no memory of previous conversations, it just receives updates, process them and so on.\n\n* A stateful Bot instead can remember what happened in the past.\nThe state here refer to a specific chat, a conversation (chat_id) between a user and a bot \"instance\".","ref":"readme.html#dispatch-model"},{"type":"extras","title":"Bot behaviours - Telegram","doc":"* `Telegram.Bot`: works with the **stateless async** dispatch model\n* `Telegram.ChatBot`: works with the **stateful chat** dispatch model","ref":"readme.html#bot-behaviours"},{"type":"extras","title":"Logging - Telegram","doc":"The library attaches two metadata fields to the internal logs: [:bot, :chat_id].\nIf your app runs more that one bot these fields can be included in your logs (ref. to the Logger config)\nto clearly identify and \"trace\" every bot's message flow.\n\n# Sample app\n\nA chat_bot app, deployed to Gigalixir PaaS and served in webhook mode: https://github.com/visciang/telegram_example","ref":"readme.html#logging"}],"content_type":"text/markdown","producer":{"name":"ex_doc","version":[48,46,51,52,46,50]}}