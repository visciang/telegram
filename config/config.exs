import Config

if config_env() == :test do
  config :telegram,
    api_base_url: "http://test:8000",
    get_updates_poll_timeout: 1
end
