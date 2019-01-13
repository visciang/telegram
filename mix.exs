defmodule Telegram.Mixfile do
  use Mix.Project

  def project do
    [
      app: :telegram,
      version: "0.5.1",
      elixir: "~> 1.5",
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
      {:hackney, "~> 1.9"},
      {:jason, "~> 1.0"},
      {:excoveralls, "~> 0.8", only: :test},
      {:meck, "~> 0.8.9", only: :test},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/visciang/telegram",
      extras: ["README.md"]
    ]
  end
end
