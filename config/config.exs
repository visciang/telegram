use Mix.Config

config :tesla,
  adapter: :hackney

import_config "#{Mix.env}.exs"
