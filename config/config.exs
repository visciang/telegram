import Config

config :logger, :console, metadata: [:bot, :chat_id]

if config_env() == :test do
  config :tesla, adapter: Tesla.Mock

  config :telegram,
    api_base_url: "http://test:8000",
    get_updates_poll_timeout_s: 1
end
