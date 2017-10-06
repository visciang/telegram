defmodule Telegram.Mixfile do
  use Mix.Project

  def project do
    [
      app: :telegram,
      version: "0.2.4",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
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
      # {:maxwell, "~> 2.2"},
      {:maxwell, git: "https://github.com/visciang/maxwell", branch: "multipart_file_content"},
      {:poison, "~> 3.1"},
      {:bypass, "~> 0.8", only: :test},
      {:excoveralls, "~> 0.7.3", only: :test},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/visciang/telegram",
      extras: ["README.md"],
    ]
  end
end
