searchNodes=[{"doc":"Telegram Bot API - HTTP-based interface","ref":"Telegram.Api.html","title":"Telegram.Api","type":"module"},{"doc":"Download a file. Reference: BOT Api Example: # send a photo {:ok, res} = Telegram.Api.request(token, &quot;sendPhoto&quot;, chat id: 12345, photo: {:file, &quot;example/photo.jpg&quot;}) # pick the 'file_obj' with the desired resolution [file_obj | ] = res[&quot;photo&quot;] # get the 'file_id' file_id = file_obj[&quot;file_id&quot;] # obtain the 'file_path' to download the file identified by 'file_id' {:ok, %{&quot;file_path&quot; =&gt; file_path}} = Telegram.Api.request(token, &quot;getFile&quot;, file_id: file_id) {:ok, file} = Telegram.Api.file(token, file_path)","ref":"Telegram.Api.html#file/2","title":"Telegram.Api.file/2","type":"function"},{"doc":"Send a Telegram Bot API request. Reference: BOT Api","ref":"Telegram.Api.html#request/3","title":"Telegram.Api.request/3","type":"function"},{"doc":"","ref":"Telegram.Api.html#t:parameters/0","title":"Telegram.Api.parameters/0","type":"type"},{"doc":"","ref":"Telegram.Api.html#t:request_result/0","title":"Telegram.Api.request_result/0","type":"type"},{"doc":"Telegram Bot behaviour. Example defmodule HelloBot do use Telegram.Bot @impl Telegram.Bot def handle_update ( %{ &quot;message&quot; =&gt; %{ &quot;text&quot; =&gt; &quot;/hello&quot; , &quot;chat&quot; =&gt; %{ &quot;id&quot; =&gt; chat_id , &quot;username&quot; =&gt; username } , &quot;message_id&quot; =&gt; message_id } } , token ) do Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : chat_id , reply_to_message_id : message_id , text : &quot;Hello \#{ username } !&quot; ) end def handle_update ( _update , _token ) do # ignore unknown updates :ok end end","ref":"Telegram.Bot.html","title":"Telegram.Bot","type":"behaviour"},{"doc":"The function receives the telegram update event.","ref":"Telegram.Bot.html#c:handle_update/2","title":"Telegram.Bot.handle_update/2","type":"callback"},{"doc":"Bot Supervisor - Asynchronous update dispatching The Bot Telegram.Bot.handle_update/2 function is called a dynamically spawned Task, so every update is handled by an isolated Task process. (this can be controlled/limited with the max_bot_concurrency option)","ref":"Telegram.Bot.Async.Supervisor.html","title":"Telegram.Bot.Async.Supervisor","type":"module"},{"doc":"Returns a specification to start this module under a supervisor. See Supervisor .","ref":"Telegram.Bot.Async.Supervisor.html#child_spec/1","title":"Telegram.Bot.Async.Supervisor.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Bot.Async.Supervisor.html#start_link/1","title":"Telegram.Bot.Async.Supervisor.start_link/1","type":"function"},{"doc":"","ref":"Telegram.Bot.Async.Supervisor.html#t:options/0","title":"Telegram.Bot.Async.Supervisor.options/0","type":"type"},{"doc":"ChatBot chat registry.","ref":"Telegram.Bot.ChatBot.Chat.Registry.html","title":"Telegram.Bot.ChatBot.Chat.Registry","type":"module"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Registry.html#child_spec/1","title":"Telegram.Bot.ChatBot.Chat.Registry.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Registry.html#lookup/2","title":"Telegram.Bot.ChatBot.Chat.Registry.lookup/2","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Registry.html#unregister/2","title":"Telegram.Bot.ChatBot.Chat.Registry.unregister/2","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Registry.html#via/2","title":"Telegram.Bot.ChatBot.Chat.Registry.via/2","type":"function"},{"doc":"ChatBot chat session server.","ref":"Telegram.Bot.ChatBot.Chat.Session.Server.html","title":"Telegram.Bot.ChatBot.Chat.Session.Server","type":"module"},{"doc":"Returns a specification to start this module under a supervisor. See Supervisor .","ref":"Telegram.Bot.ChatBot.Chat.Session.Server.html#child_spec/1","title":"Telegram.Bot.ChatBot.Chat.Session.Server.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Session.Server.html#handle_update/3","title":"Telegram.Bot.ChatBot.Chat.Session.Server.handle_update/3","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Session.Server.html#start_link/1","title":"Telegram.Bot.ChatBot.Chat.Session.Server.start_link/1","type":"function"},{"doc":"ChatBot chat session supervisor.","ref":"Telegram.Bot.ChatBot.Chat.Session.Supervisor.html","title":"Telegram.Bot.ChatBot.Chat.Session.Supervisor","type":"module"},{"doc":"Returns a specification to start this module under a supervisor. See Supervisor .","ref":"Telegram.Bot.ChatBot.Chat.Session.Supervisor.html#child_spec/1","title":"Telegram.Bot.ChatBot.Chat.Session.Supervisor.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Session.Supervisor.html#start_child/2","title":"Telegram.Bot.ChatBot.Chat.Session.Supervisor.start_child/2","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Session.Supervisor.html#start_link/1","title":"Telegram.Bot.ChatBot.Chat.Session.Supervisor.start_link/1","type":"function"},{"doc":"ChatBot chat supervisor.","ref":"Telegram.Bot.ChatBot.Chat.Supervisor.html","title":"Telegram.Bot.ChatBot.Chat.Supervisor","type":"module"},{"doc":"Returns a specification to start this module under a supervisor. See Supervisor .","ref":"Telegram.Bot.ChatBot.Chat.Supervisor.html#child_spec/1","title":"Telegram.Bot.ChatBot.Chat.Supervisor.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Chat.Supervisor.html#start_link/1","title":"Telegram.Bot.ChatBot.Chat.Supervisor.start_link/1","type":"function"},{"doc":"ChatBot top supervisor.","ref":"Telegram.Bot.ChatBot.Supervisor.html","title":"Telegram.Bot.ChatBot.Supervisor","type":"module"},{"doc":"Returns a specification to start this module under a supervisor. See Supervisor .","ref":"Telegram.Bot.ChatBot.Supervisor.html#child_spec/1","title":"Telegram.Bot.ChatBot.Supervisor.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Supervisor.html#start_link/1","title":"Telegram.Bot.ChatBot.Supervisor.start_link/1","type":"function"},{"doc":"","ref":"Telegram.Bot.ChatBot.Supervisor.html#t:options/0","title":"Telegram.Bot.ChatBot.Supervisor.options/0","type":"type"},{"doc":"","ref":"Telegram.Bot.Poller.html","title":"Telegram.Bot.Poller","type":"module"},{"doc":"Returns a specification to start this module under a supervisor. arg is passed as the argument to Task.start_link/1 in the :start field of the spec. For more information, see the Supervisor module, the Supervisor.child_spec/2 function and the Supervisor.child_spec/0 type.","ref":"Telegram.Bot.Poller.html#child_spec/1","title":"Telegram.Bot.Poller.child_spec/1","type":"function"},{"doc":"","ref":"Telegram.Bot.Poller.html#start_link/1","title":"Telegram.Bot.Poller.start_link/1","type":"function"},{"doc":"","ref":"Telegram.Bot.Poller.html#t:handle_update/0","title":"Telegram.Bot.Poller.handle_update/0","type":"type"},{"doc":"Bot utilities","ref":"Telegram.Bot.Utils.html","title":"Telegram.Bot.Utils","type":"module"},{"doc":"Get the &quot;chat&quot; field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_chat/1","title":"Telegram.Bot.Utils.get_chat/1","type":"function"},{"doc":"Get the &quot;from.user&quot; field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_from_username/1","title":"Telegram.Bot.Utils.get_from_username/1","type":"function"},{"doc":"Get the sent &quot;date&quot; field in an Update object, if present","ref":"Telegram.Bot.Utils.html#get_sent_date/1","title":"Telegram.Bot.Utils.get_sent_date/1","type":"function"},{"doc":"Process name atom maker. Composed by Supervisor/GenServer/_ module name + bot behaviour module name","ref":"Telegram.Bot.Utils.html#name/2","title":"Telegram.Bot.Utils.name/2","type":"function"},{"doc":"Telegram Chat Bot behaviour. The difference with Telegram.Bot behaviour is that the Telegram.ChatBot is &quot;statefull&quot; per chat_id, (see chat_state argument) Example defmodule HelloBot do use Telegram.ChatBot @impl Telegram.ChatBot def init ( _chat ) do count_state = 0 { :ok , count_state } end @impl Telegram.ChatBot def handle_update ( %{ &quot;message&quot; =&gt; %{ &quot;chat&quot; =&gt; %{ &quot;id&quot; =&gt; chat_id } } } , token , count_state ) do count_state = count_state + 1 Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : chat_id , text : &quot;Hey! You sent me \#{ count_state } messages&quot; ) { :ok , count_state } end def handle_update ( update , _token , count_state ) do # ignore unknown updates { :ok , count_state } end end","ref":"Telegram.ChatBot.html","title":"Telegram.ChatBot","type":"behaviour"},{"doc":"Receives the telegram update event and the &quot;current&quot; chat_state. Return the &quot;updated&quot; chat_state.","ref":"Telegram.ChatBot.html#c:handle_update/3","title":"Telegram.ChatBot.handle_update/3","type":"callback"},{"doc":"Invoked once when the chat starts. Return the initial chat_state.","ref":"Telegram.ChatBot.html#c:init/1","title":"Telegram.ChatBot.init/1","type":"callback"},{"doc":"","ref":"Telegram.ChatBot.html#t:chat/0","title":"Telegram.ChatBot.chat/0","type":"type"},{"doc":"","ref":"Telegram.ChatBot.html#t:chat_state/0","title":"Telegram.ChatBot.chat_state/0","type":"type"},{"doc":"Telegram types","ref":"Telegram.Types.html","title":"Telegram.Types","type":"module"},{"doc":"","ref":"Telegram.Types.html#t:max_bot_concurrency/0","title":"Telegram.Types.max_bot_concurrency/0","type":"type"},{"doc":"","ref":"Telegram.Types.html#t:method/0","title":"Telegram.Types.method/0","type":"type"},{"doc":"","ref":"Telegram.Types.html#t:token/0","title":"Telegram.Types.token/0","type":"type"},{"doc":"","ref":"Telegram.Types.html#t:update/0","title":"Telegram.Types.update/0","type":"type"},{"doc":"Telegram library for the Elixir language.","ref":"readme.html","title":"Telegram","type":"extras"},{"doc":"The package can be installed by adding telegram to your list of dependencies in mix.exs : def deps do [ { :telegram , git : &quot;https://github.com/visciang/telegram.git&quot; , tag : &quot;xxx&quot; } ] end Telegram Bot API Telegram Bot API request. The module expose a light layer over the Telegram Bot API HTTP-based interface, it does not expose any &quot;(data)binding&quot; over the HTTP interface and tries to abstract away only the boilerplate for building / sending / serializing the API requests. Compared to a full-binded interface it could result less elixir frendly but it will work with any version of the Bot API, hopefully without updates or incompatibily with new Bot API versions (as much as they remain backward compatible). References: API specification Bot intro for developers Given the token of your Bot you can issue any request using: method: Telegram API method name (ex. &quot;getMe&quot;, &quot;sendMessage&quot;) options: Telegram API method specific parameters (you can use elixir native types)","ref":"readme.html#installation","title":"Telegram - Installation","type":"extras"},{"doc":"Given the bot token (something like): token = &quot;123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11&quot; getMe Telegram.Api . request ( token , &quot;getMe&quot; ) { :ok , %{ &quot;first_name&quot; =&gt; &quot;Abc&quot; , &quot;id&quot; =&gt; 1234567 , &quot;is_bot&quot; =&gt; true , &quot;username&quot; =&gt; &quot;ABC&quot; } } sendMessage Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : 876532 , text : &quot;Hello! .. silently&quot; , disable_notification : true ) { :ok , %{ &quot;chat&quot; =&gt; %{ &quot;first_name&quot; =&gt; &quot;Firstname&quot; , &quot;id&quot; =&gt; 208255328 , &quot;last_name&quot; =&gt; &quot;Lastname&quot; , &quot;type&quot; =&gt; &quot;private&quot; , &quot;username&quot; =&gt; &quot;xxxx&quot; } , &quot;date&quot; =&gt; 1505118722 , &quot;from&quot; =&gt; %{ &quot;first_name&quot; =&gt; &quot;Yyy&quot; , &quot;id&quot; =&gt; 234027650 , &quot;is_bot&quot; =&gt; true , &quot;username&quot; =&gt; &quot;yyy&quot; } , &quot;message_id&quot; =&gt; 1402 , &quot;text&quot; =&gt; &quot;Hello! .. silently&quot; } } getUpdates Telegram.Api . request ( token , &quot;getUpdates&quot; , offset : - 1 , timeout : 30 ) { :ok , [ %{ &quot;message&quot; =&gt; %{ &quot;chat&quot; =&gt; %{ &quot;first_name&quot; =&gt; &quot;Firstname&quot; , &quot;id&quot; =&gt; 208255328 , &quot;last_name&quot; =&gt; &quot;Lastname&quot; , &quot;type&quot; =&gt; &quot;private&quot; , &quot;username&quot; =&gt; &quot;xxxx&quot; } , &quot;date&quot; =&gt; 1505118098 , &quot;from&quot; =&gt; %{ &quot;first_name&quot; =&gt; &quot;Firstname&quot; , &quot;id&quot; =&gt; 208255328 , &quot;is_bot&quot; =&gt; false , &quot;language_code&quot; =&gt; &quot;en-IT&quot; , &quot;last_name&quot; =&gt; &quot;Lastname&quot; , &quot;username&quot; =&gt; &quot;xxxx&quot; } , &quot;message_id&quot; =&gt; 1401 , &quot;text&quot; =&gt; &quot;Hello!&quot; } , &quot;update_id&quot; =&gt; 129745295 } ] }","ref":"readme.html#examples","title":"Telegram - Examples:","type":"extras"},{"doc":"If a API parameter has a InputFile type and you want to send a local file, for example a photo stored locally at &quot;/tmp/photo.jpg&quot;, just wrap the parameter value in a tuple {:file, &quot;/tmp/photo.jpg&quot;} . If the file content is in memory wrap it in {:file_content, data, &quot;photo.jpg&quot;} tuple. sendPhoto Telegram.Api . request ( token , &quot;sendPhoto&quot; , chat_id : 876532 , photo : { :file , &quot;/tmp/photo.jpg&quot; } ) Telegram.Api . request ( token , &quot;sendPhoto&quot; , chat_id : 876532 , photo : { :file_content , photo , &quot;photo.jpg&quot; } )","ref":"readme.html#sending-files","title":"Telegram - Sending files","type":"extras"},{"doc":"To download a file from the telegram server you need a file_path pointer to the file. With that you can download the file via Telegram.Api.file . { :ok , res } = Telegram.Api . request ( token , &quot;sendPhoto&quot; , chat_id : 12345 , photo : { :file , &quot;example/photo.jpg&quot; } ) # pick the &#39;file_obj&#39; with the desired resolution [ file_obj | _ ] = res [ &quot;photo&quot; ] # get the &#39;file_id&#39; file_id = file_obj [ &quot;file_id&quot; ] getFile { :ok , %{ &quot;file_path&quot; =&gt; file_path } } = Telegram.Api . request ( token , &quot;getFile&quot; , file_id : file_id ) { :ok , file } = Telegram.Api . file ( token , file_path )","ref":"readme.html#downloading-files","title":"Telegram - Downloading files","type":"extras"},{"doc":"If a API parameter has a &quot;A JSON-serialized object&quot; type (InlineKeyboardMarkup, ReplyKeyboardMarkup, etc), just wrap the parameter value in a tuple {:json, value} . Reference: Keyboards , Inline Keyboards sendMessage with keyboard keyboard = [ [ &quot;A0&quot; , &quot;A1&quot; ] , [ &quot;B0&quot; , &quot;B1&quot; , &quot;B2&quot; ] ] keyboard_markup = %{ one_time_keyboard : true , keyboard : keyboard } Telegram.Api . request ( token , &quot;sendMessage&quot; , chat_id : 876532 , text : &quot;Here a keyboard!&quot; , reply_markup : { :json , keyboard_markup } ) Telegram Bot","ref":"readme.html#reply-markup","title":"Telegram - Reply Markup","type":"extras"},{"doc":"Check the examples under example/example_*.exs . You can run them as a Mix self-contained script. BOT_TOKEN=&quot;...&quot; example/example_chatbot.exs","ref":"readme.html#quick-start","title":"Telegram - Quick start","type":"extras"},{"doc":"The Telegram platform supports two ways of processing bot updates, getUpdates and setWebhook . getUpdates is a pull mechanism, setwebhook is push. (ref: bots webhook ) This library currently implements the getUpdates mechanism. This mode can be used in a dev environment or if your bot doesn't need to &quot;scale&quot;. Being in pull it works well behind a firewall (or behind an home internet router). The webhook mode is in the development plan but, being this project a personal playground, unless sponsored there isn't an estimated date.","ref":"readme.html#bot-updates-processing","title":"Telegram - Bot updates processing","type":"extras"},{"doc":"We can define stateless / statefull bot. A stateless Bot has no memory of previous conversations, it just receives updates, process them and so on. A statefull Bot instead can remember what happened in the past. The state here refer to a specific chat, a conversation (chat_id) between a user and a bot &quot;instance&quot;.","ref":"readme.html#dispatch-model","title":"Telegram - Dispatch model","type":"extras"},{"doc":"Telegram.Bot : works with the stateless async dispatch model Telegram.ChatBot : works with the statefull chat dispatch model Sample app A chat_bot app: https://github.com/visciang/telegram_example","ref":"readme.html#bot-behaviours","title":"Telegram - Bot behaviours","type":"extras"}]