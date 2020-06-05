defmodule Mechanize.MixProject do
  use Mix.Project

  @version "0.1.0-dev"

  def project do
    [
      app: :mechanize,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :transitive],
      elixirc_paths: elixirc_paths(Mix.env()),

      # Docs
      name: "Mechanize",
      source_url: "https://github.com/ghonorato/mechanize",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:excoveralls, github: "parroty/excoveralls", only: [:dev, :test]},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:bypass, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end
end
