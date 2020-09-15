use Mix.Config

config :telegram, :tesla,
  adapter: Tesla.Adapter.Gun

if Mix.env() == :test do
  config :telegram,
    api_base_url: "http://test:8000",
    get_updates_poll_timeout: 1
end
