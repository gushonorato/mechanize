defmodule Mechanize.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :mechanize,
      version: @version,
      elixir: "~> 1.13.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :transitive],
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Build web scrapers and automate interaction with websites in Elixir with ease!",
      package: package(),

      # Docs
      name: "Mechanize",
      source_url: "https://github.com/gushonorato/mechanize",
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
      {:httpoison, "~> 1.8.2"},
      {:floki, "~> 0.33.1"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, github: "parroty/excoveralls", only: [:dev, :test]},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:bypass, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.28.4", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      maintainers: ["Gustavo Honorato"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gushonorato/mechanize"}
    ]
  end
end
