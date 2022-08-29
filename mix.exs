defmodule Telegram.Mixfile do
  use Mix.Project

  def project do
    [
      app: :telegram,
      version: "0.20.3",
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
      # plug cowboy
      {:plug_cowboy, "~> 2.5"},
      # tesla gun adapter + deps
      {:tesla, "~> 1.0"},
      {:gun, "~> 1.3"},
      {:cowlib, "~> 2.11", override: true},
      {:ssl_verify_fun, "~> 1.1"},
      {:castore, "~> 0.1"},
      {:idna, "~> 6.1"},
      # tesla json encoder
      {:jason, "~> 1.0"},
      # retry
      {:retry, "~> 0.14"},
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
