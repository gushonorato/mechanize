defmodule Mechanizex.MixProject do
  use Mix.Project

  def project do
    [
      app: :mechanizex,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:floki, "~> 0.21.0"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:mox, "~> 0.5", only: :test},
      {:excoveralls, github: "parroty/excoveralls"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false}
    ]
  end
end
