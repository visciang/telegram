import Config

config :logger, :console, metadata: [:bot, :chat_id]
config :tesla, adapter: {Tesla.Adapter.Finch, name: Adapter.Finch}
