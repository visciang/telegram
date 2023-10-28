defmodule Telegram.Mixfile do
  use Mix.Project

  def project do
    [
      app: :telegram,
      version: "1.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        docs: :dev
      ],
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      dialyzer: [
        plt_local_path: "_build/plts"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug, "~> 1.14"},
      # HTTP servers
      {:plug_cowboy, "~> 2.5", optional: true},
      {:bandit, "~> 1.0", optional: true},
      # HTTP client
      {:tesla, "~> 1.0"},
      {:hackney, "~> 1.18", only: :test},
      # tesla json encoder
      {:jason, "~> 1.0"},
      # coverage
      {:excoveralls, "~> 0.12", only: :test},
      # documentation
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      # dialyzer
      {:credo, "~> 1.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/visciang/telegram",
      extras: ["README.md"]
    ]
  end
end
