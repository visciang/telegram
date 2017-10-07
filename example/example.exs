#
# mix run example/example.exs
#
# Fill token, username, auth with yours.

defmodule Example.Bot do
  require Logger

  use Telegram.Bot,
    token: ,
    username: ,
    auth: ,
    purge: true

  command "ciao", args do
    request "sendMessage", chat_id: update["chat"]["id"],
      text: "ciao! #{inspect args}"
  end

  command ["arrivederci", "goodbye"], args do
    request "sendMessage", chat_id: update["chat"]["id"],
      text: "arrivederci! #{inspect args}"
  end

  command "echo", _args do
    # update var is injected in every macro body
    # and holds the received telegram Update object
    request "sendMessage", chat_id: update["chat"]["id"],
      text: "received update: #{inspect update}"
  end

  command "photo", _args do
    request "sendPhoto", chat_id: update["chat"]["id"], photo: {:file, "./example/photo.jpg"}
  end

  command "photo2", _args do
    filename = "./example/photo.jpg"
    photo = File.read!(filename)
    request "sendPhoto", chat_id: update["chat"]["id"], photo: {:file_content, photo, filename}
  end

  command "halt", _ do
    request "sendMessage", chat_id: update["chat"]["id"],
      text: "bye"

    halt "HALT!"
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
    Logger.debug("edited_message")
  end

  channel_post do
    Logger.debug("channel_post")
  end

  edited_channel_post do
    Logger.debug("edited_channel_post")
  end

  inline_query _query do
    Logger.debug("inline_query")
  end

  chosen_inline_result _query do
    Logger.debug("chosen_inline_result")
  end

  callback_query do
    Logger.debug("callback_query")
  end

  shipping_query do
    Logger.debug("shipping_query")
  end

  pre_checkout_query do
    Logger.debug("pre_checkout_query")
  end

  any do
    Logger.debug("any")
  end
end

{:ok, _} = Example.Bot.start_link()
Process.sleep(:infinity)
