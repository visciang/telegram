defmodule Telegram.Mixfile do
  use Mix.Project

  def project do
    [
      app: :telegram,
      version: "0.7.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.0"},
      # tesla gun adapter
      {:gun, "~> 1.3"},
      {:ssl_verify_fun, "~> 1.1"},  # note: gun adapter dependency
      {:castore, "~> 0.1"},         # note: gun adapter dependency
      # tesla json encoder
      {:jason, "~> 1.0"},
      # coverage
      {:excoveralls, "~> 0.12", only: :test},
      # documentation
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      # dialyzer
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/visciang/telegram",
      extras: ["README.md"]
    ]
  end
end
