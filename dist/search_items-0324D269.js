searchNodes=[{"doc":"Telegram Bot API - HTTP-based interface","ref":"Telegram.Api.html","title":"Telegram.Api","type":"module"},{"doc":"Download a file. Reference: BOT Api Example: # send a photo { :ok , res } = Telegram.Api . request ( token , &quot;sendPhoto&quot; , chat_id : 12345 , photo : { :file , &quot;example/photo.jpg&quot; } ) # pick the &#39;file_obj&#39; with the desired resolution [ file_obj | _ ] = res [ &quot;photo&quot; ] # get the &#39;file_id&#39; file_id = file_obj [ &quot;file_id&quot; ] # obtain the &#39;file_path&#39; to download the file identified by &#39;file_id&#39; { :ok , %{ &quot;file_path&quot; =&gt; file_path } } = Telegram.Api . request ( token , &quot;getFile&quot; , file_id : file_id ) { :ok , file } = Telegram.Api . file ( token , file_path )","ref":"Telegram.Api.html#file/2","title":"Telegram.Api.file/2","type":"function"},{"doc":"Send a Telegram Bot API request. The request parameters map to the bots API parameters. Integer String Boolean Float : Elixir native data type JSON-serialized : {:json, _} tuple InputFile : {:file, _} or {:file_content, _, _} tuple Reference: BOT Api","ref":"Telegram.Api.html#request/3","title":"Telegram.Api.request/3","type":"function"},{"doc":"","ref":"Telegram.Api.html#t:parameter_name/0","title":"Telegram.Api.parameter_name/0","type":"type"},{"doc":"","ref":"Telegram.Api.html#t:parameter_value/0","title":"Telegram.Api.parameter_value/0","type":"type"},{"doc":"","ref":"Telegram.Api.html#t:parameters/0","title":"Telegram.Api.parameters/0","type":"type"},{"doc":"","ref":"Telegram.Api.html#t:request_result/0","title":"Telegram.Api.request_result/0","type":"type"},{"doc":"Telegram Bot behaviour. Example defmodule HelloBot do use Telegram.Bot @impl Telegram.Bot def handle_update ( %{ &quot;message&quot; =&gt; %{ &quot;text&quot; =&gt; &quot;/hello&quot; , &quot;chat&quot; =&gt; %{ &quot;id&quot; =&gt; chat_id , &quot;username&quot; =&gt; username } , &quot;message_id&quot; =&gt; message_id } } , token ) do Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : chat_id , reply_to_message_id : message_id , text : &quot;Hello \#{ username } !&quot; ) end def handle_update ( _update , _token ) do # ignore unknown updates :ok end end","ref":"Telegram.Bot.html","title":"Telegram.Bot","type":"behaviour"},{"doc":"The function receives the telegram update event.","ref":"Telegram.Bot.html#c:handle_update/2","title":"Telegram.Bot.handle_update/2","type":"callback"},{"doc":"Dispatch behaviour","ref":"Telegram.Bot.Dispatch.html","title":"Telegram.Bot.Dispatch","type":"behaviour"},{"doc":"","ref":"Telegram.Bot.Dispatch.html#c:dispatch_update/2","title":"Telegram.Bot.Dispatch.dispatch_update/2","type":"callback"},{"doc":"","ref":"Telegram.Bot.Dispatch.html#t:t/0","title":"Telegram.Bot.Dispatch.t/0","type":"type"},{"doc":"Bot utilities","ref":"Telegram.Bot.Utils.html","title":"Telegram.Bot.Utils","type":"module"},{"doc":"Get the &quot;chat&quot; field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_chat/1","title":"Telegram.Bot.Utils.get_chat/1","type":"function"},{"doc":"Get the &quot;from.user&quot; field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_from_username/1","title":"Telegram.Bot.Utils.get_from_username/1","type":"function"},{"doc":"Get the sent &quot;date&quot; field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_sent_date/1","title":"Telegram.Bot.Utils.get_sent_date/1","type":"function"},{"doc":"Process name atom maker. Composed by Supervisor/GenServer/_ module name + bot behaviour module name","ref":"Telegram.Bot.Utils.html#name/2","title":"Telegram.Bot.Utils.name/2","type":"function"},{"doc":"Telegram Chat Bot behaviour. The difference with Telegram.Bot behaviour is that the Telegram.ChatBot is &quot;statefull&quot; per chat_id, (see chat_state argument). Given that every &quot;conversation&quot; is associated with a long running process is up to you to consider a session timeout in your bot state machine design. If you don't you will saturate the max_bot_concurrency capacity and then your bot won't accept any new conversation. For this you can leverage the underlying gen_server timeout including the timeout in the return value of the init/1 or handle_update/3 callbacks or, if you need a more complex behaviour, via explicit timers in you bot. Example defmodule HelloBot do use Telegram.ChatBot @session_ttl 60 * 1_000 @impl Telegram.ChatBot def init ( _chat ) do count_state = 0 { :ok , count_state , @session_ttl } end @impl Telegram.ChatBot def handle_update ( %{ &quot;message&quot; =&gt; %{ &quot;chat&quot; =&gt; %{ &quot;id&quot; =&gt; chat_id } } } , token , count_state ) do count_state = count_state + 1 Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : chat_id , text : &quot;Hey! You sent me \#{ count_state } messages&quot; ) { :ok , count_state , @session_ttl } end def handle_update ( update , _token , count_state ) do # ignore unknown updates { :ok , count_state , @session_ttl } end @impl Telegram.ChatBot def handle_timeout ( token , chat_id , count_state ) do Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : chat_id , text : &quot;See you!&quot; ) super ( token , chat_id , count_state ) end end","ref":"Telegram.ChatBot.html","title":"Telegram.ChatBot","type":"behaviour"},{"doc":"On timeout callback. A default implementation is injected with &quot;use Telegram.ChatBot&quot;, it just stops the bot.","ref":"Telegram.ChatBot.html#c:handle_timeout/3","title":"Telegram.ChatBot.handle_timeout/3","type":"callback"},{"doc":"Receives the telegram update event and the &quot;current&quot; chat_state. Return the &quot;updated&quot; chat_state.","ref":"Telegram.ChatBot.html#c:handle_update/3","title":"Telegram.ChatBot.handle_update/3","type":"callback"},{"doc":"Invoked once when the chat starts. Return the initial chat_state.","ref":"Telegram.ChatBot.html#c:init/1","title":"Telegram.ChatBot.init/1","type":"callback"},{"doc":"","ref":"Telegram.ChatBot.html#t:chat/0","title":"Telegram.ChatBot.chat/0","type":"type"},{"doc":"","ref":"Telegram.ChatBot.html#t:chat_state/0","title":"Telegram.ChatBot.chat_state/0","type":"type"},{"doc":"","ref":"Telegram.ChatBot.html#t:t/0","title":"Telegram.ChatBot.t/0","type":"type"},{"doc":"Telegram poller supervisor. Usage In you app supervisor tree: bot_config = [ token : Application . fetch_env! ( :my_app , :token_counter_bot ) , max_bot_concurrency : Application . fetch_env! ( :my_app , :max_bot_concurrency ) ] children = [ { Telegram.Poller , bots : [ { MyApp.Bot , bot_config } ] } ... ] opts = [ strategy : :one_for_one , name : MyApp.Supervisor ] Supervisor . start_link ( children , opts )","ref":"Telegram.Poller.html","title":"Telegram.Poller","type":"module"},{"doc":"Returns a specification to start this module under a supervisor. See Supervisor .","ref":"Telegram.Poller.html#child_spec/1","title":"Telegram.Poller.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Poller.html#start_link/1","title":"Telegram.Poller.start_link/1","type":"function"},{"doc":"Telegram types","ref":"Telegram.Types.html","title":"Telegram.Types","type":"module"},{"doc":"","ref":"Telegram.Types.html#t:bot_opts/0","title":"Telegram.Types.bot_opts/0","type":"type"},{"doc":"","ref":"Telegram.Types.html#t:bot_spec/0","title":"Telegram.Types.bot_spec/0","type":"type"},{"doc":"","ref":"Telegram.Types.html#t:max_bot_concurrency/0","title":"Telegram.Types.max_bot_concurrency/0","type":"type"},{"doc":"","ref":"Telegram.Types.html#t:method/0","title":"Telegram.Types.method/0","type":"type"},{"doc":"","ref":"Telegram.Types.html#t:token/0","title":"Telegram.Types.token/0","type":"type"},{"doc":"","ref":"Telegram.Types.html#t:update/0","title":"Telegram.Types.update/0","type":"type"},{"doc":"Telegram Webhook supervisor. Usage In you app supervisor tree: webhook_config = [ host : &quot;myapp.public-domain.com&quot; , port : 443 , local_port : 4_000 ] bot_config = [ token : Application . fetch_env! ( :my_app , :token_counter_bot ) , max_bot_concurrency : Application . fetch_env! ( :my_app , :max_bot_concurrency ) ] children = [ { Telegram.Webhook , config : webhook_config , bots : [ { MyApp.Bot , bot_config } ] } ... ] opts = [ strategy : :one_for_one , name : MyApp.Supervisor ] Supervisor . start_link ( children , opts ) Ref https://core.telegram.org/bots/api#setwebhook https://core.telegram.org/bots/webhooks","ref":"Telegram.Webhook.html","title":"Telegram.Webhook","type":"module"},{"doc":"Returns a specification to start this module under a supervisor. See Supervisor .","ref":"Telegram.Webhook.html#child_spec/1","title":"Telegram.Webhook.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Webhook.html#start_link/1","title":"Telegram.Webhook.start_link/1","type":"function"},{"doc":"Webhook configuration. host : (reverse proxy) hostname of the HTTPS webhook url (required) port : (reverse proxy) port of the HTTPS webhook url (optional, default: 443) local_port : (backend) port of the application HTTP web server (optional, default: 4000) max_connections : maximum allowed number of simultaneous connections to the webhook for update delivery (optional, defaults 40)","ref":"Telegram.Webhook.html#t:config/0","title":"Telegram.Webhook.config/0","type":"type"},{"doc":"Telegram library for the Elixir language. It provides: an inteface to the Telegram Bot HTTP-based APIs ( Telegram.Api ) a couple of bot behaviours to define you bots ( Telegram.Bot , Telegram.ChatBot ) two bot runners ( Telegram.Poller , Telegram.Webhook )","ref":"readme.html","title":"Telegram","type":"extras"},{"doc":"The package can be installed by adding telegram to your list of dependencies in mix.exs : def deps do [ { :telegram , git : &quot;https://github.com/visciang/telegram.git&quot; , tag : &quot;xxx&quot; } ] end Telegram Bot API This module expose a light layer over the Telegram Bot API HTTP-based interface, it does not expose any &quot;(data)binding&quot; over the HTTP interface and tries to abstract away only the boilerplate for building / sending / serializing the API requests. Compared to a full data-binded interface it could result less &quot;typed frendly&quot; but it will work with any version of the Bot API, hopefully without updates or incompatibily with new Bot API versions (as much as they remain backward compatible). References: API specification Bot intro for developers Given the token of your Bot you can issue any request using: method: Telegram API method name (ex. &quot;getMe&quot;, &quot;sendMessage&quot;) options: Telegram API method specific parameters (you can use elixir native types)","ref":"readme.html#installation","title":"Telegram - Installation","type":"extras"},{"doc":"Given the bot token (something like): token = &quot;123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11&quot; getMe Telegram.Api . request ( token , &quot;getMe&quot; ) { :ok , %{ &quot;first_name&quot; =&gt; &quot;Abc&quot; , &quot;id&quot; =&gt; 1234567 , &quot;is_bot&quot; =&gt; true , &quot;username&quot; =&gt; &quot;ABC&quot; } } sendMessage Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : 876532 , text : &quot;Hello! .. silently&quot; , disable_notification : true ) { :ok , %{ &quot;chat&quot; =&gt; %{ &quot;first_name&quot; =&gt; &quot;Firstname&quot; , &quot;id&quot; =&gt; 208255328 , &quot;last_name&quot; =&gt; &quot;Lastname&quot; , &quot;type&quot; =&gt; &quot;private&quot; , &quot;username&quot; =&gt; &quot;xxxx&quot; } , &quot;date&quot; =&gt; 1505118722 , &quot;from&quot; =&gt; %{ &quot;first_name&quot; =&gt; &quot;Yyy&quot; , &quot;id&quot; =&gt; 234027650 , &quot;is_bot&quot; =&gt; true , &quot;username&quot; =&gt; &quot;yyy&quot; } , &quot;message_id&quot; =&gt; 1402 , &quot;text&quot; =&gt; &quot;Hello! .. silently&quot; } } getUpdates Telegram.Api . request ( token , &quot;getUpdates&quot; , offset : - 1 , timeout : 30 ) { :ok , [ %{ &quot;message&quot; =&gt; %{ &quot;chat&quot; =&gt; %{ &quot;first_name&quot; =&gt; &quot;Firstname&quot; , &quot;id&quot; =&gt; 208255328 , &quot;last_name&quot; =&gt; &quot;Lastname&quot; , &quot;type&quot; =&gt; &quot;private&quot; , &quot;username&quot; =&gt; &quot;xxxx&quot; } , &quot;date&quot; =&gt; 1505118098 , &quot;from&quot; =&gt; %{ &quot;first_name&quot; =&gt; &quot;Firstname&quot; , &quot;id&quot; =&gt; 208255328 , &quot;is_bot&quot; =&gt; false , &quot;language_code&quot; =&gt; &quot;en-IT&quot; , &quot;last_name&quot; =&gt; &quot;Lastname&quot; , &quot;username&quot; =&gt; &quot;xxxx&quot; } , &quot;message_id&quot; =&gt; 1401 , &quot;text&quot; =&gt; &quot;Hello!&quot; } , &quot;update_id&quot; =&gt; 129745295 } ] }","ref":"readme.html#examples","title":"Telegram - Examples:","type":"extras"},{"doc":"If an API parameter has a InputFile type and you want to send a local file, for example a photo stored at &quot;/tmp/photo.jpg&quot;, just wrap the parameter value in a {:file, &quot;/tmp/photo.jpg&quot;} tuple. If the file content is in memory wrap it in a {:file_content, data, &quot;photo.jpg&quot;} tuple. sendPhoto Telegram.Api . request ( token , &quot;sendPhoto&quot; , chat_id : 876532 , photo : { :file , &quot;/tmp/photo.jpg&quot; } ) Telegram.Api . request ( token , &quot;sendPhoto&quot; , chat_id : 876532 , photo : { :file_content , photo , &quot;photo.jpg&quot; } )","ref":"readme.html#sending-files","title":"Telegram - Sending files","type":"extras"},{"doc":"To download a file from the telegram server you need a file_path pointer to the file. With that you can download the file via Telegram.Api.file . { :ok , res } = Telegram.Api . request ( token , &quot;sendPhoto&quot; , chat_id : 12345 , photo : { :file , &quot;example/photo.jpg&quot; } ) # pick the &#39;file_obj&#39; with the desired resolution [ file_obj | _ ] = res [ &quot;photo&quot; ] # get the &#39;file_id&#39; file_id = file_obj [ &quot;file_id&quot; ] getFile { :ok , %{ &quot;file_path&quot; =&gt; file_path } } = Telegram.Api . request ( token , &quot;getFile&quot; , file_id : file_id ) { :ok , file } = Telegram.Api . file ( token , file_path )","ref":"readme.html#downloading-files","title":"Telegram - Downloading files","type":"extras"},{"doc":"If an API parameter has a non primitive scalar type it is explicitly pointed out as &quot;A JSON-serialized object&quot; (ie InlineKeyboardMarkup , ReplyKeyboardMarkup , etc). In this case you can wrap the parameter value in a {:json, value} tuple. sendMessage with keyboard keyboard = [ [ &quot;A0&quot; , &quot;A1&quot; ] , [ &quot;B0&quot; , &quot;B1&quot; , &quot;B2&quot; ] ] keyboard_markup = %{ one_time_keyboard : true , keyboard : keyboard } Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : 876532 , text : &quot;Here a keyboard!&quot; , reply_markup : { :json , keyboard_markup } ) Telegram Bot","ref":"readme.html#json-serialized-object-parameters","title":"Telegram - JSON-serialized object parameters","type":"extras"},{"doc":"Check the examples under example/example_*.exs . You can run them as a Mix self-contained script. BOT_TOKEN=&quot;...&quot; example/example_chatbot.exs","ref":"readme.html#quick-start","title":"Telegram - Quick start","type":"extras"},{"doc":"The Telegram platform supports two ways of processing bot updates, getUpdates and setWebhook . getUpdates is a pull mechanism, setwebhook is push. (ref: bots webhook ) This library currently implements both models via two supervisors. Poller This mode can be used in a dev environment or if your bot doesn't need to &quot;scale&quot;. Being in pull it works well behind a firewall (or behind an home internet router). Refer to the Telegram.Poller module docs fo more info. Telegram Client Config The Telegram HTTP Client is based on Tesla . The Tesla.Adapter and options should be configured via the [:tesla, :adapter] application environment key. (ref. https://hexdocs.pm/tesla/readme.html#adapters ) For example, a good default could be: config :tesla , adapter : { Tesla.Adapter.Hackney , [ recv_timeout : 30_000 ] } a dependency should be added accordingly in your mix.exs : defp deps do [ { :telegram , git : &quot;https://github.com/visciang/telegram.git&quot; , tag : &quot;xxx&quot; } , { :hackney , &quot;~&gt; 1.18&quot; } , # ... ] end Webhook This mode interface with the telegram servers via a webhook, best for production use. The app is meant to be served over HTTP, a reverse proxy should be plance in front of it, facing the public network over HTTPS. Refer to the Telegram.Webhook module docs for more info.","ref":"readme.html#bot-updates-processing","title":"Telegram - Bot updates processing","type":"extras"},{"doc":"We can define stateless / statefull bot. A stateless Bot has no memory of previous conversations, it just receives updates, process them and so on. A statefull Bot instead can remember what happened in the past. The state here refer to a specific chat, a conversation (chat_id) between a user and a bot &quot;instance&quot;.","ref":"readme.html#dispatch-model","title":"Telegram - Dispatch model","type":"extras"},{"doc":"Telegram.Bot : works with the stateless async dispatch model Telegram.ChatBot : works with the statefull chat dispatch model","ref":"readme.html#bot-behaviours","title":"Telegram - Bot behaviours","type":"extras"},{"doc":"The library attach two metadata fields to the internal logs: [:bot, :chat_id]. If your app run more that one bot these fields can be included in your logs (ref. to the Logger config) to clearly identify and &quot;trace&quot; every BOT message flow. Sample app A chat_bot app: https://github.com/visciang/telegram_example","ref":"readme.html#logging","title":"Telegram - Logging","type":"extras"}]