defmodule Buzzword.Bingo.Game.MixProject do
  use Mix.Project

  def project do
    [
      app: :buzzword_bingo_game,
      version: "0.1.43",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      name: "Buzzword Bingo Game",
      source_url: source_url(),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp source_url do
    "https://github.com/RaymondLoranger/buzzword_bingo_game"
  end

  defp description do
    """
    A game struct and functions for the Multi-Player Buzzword Bingo game.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "config/persist*.exs"],
      maintainers: ["Raymond Loranger"],
      licenses: ["MIT"],
      links: %{"GitHub" => source_url()}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:buzzword_bingo_player, "~> 0.1"},
      {:buzzword_bingo_square, "~> 0.1"},
      {:buzzword_cache, "~> 0.1"},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:persist_config, "~> 0.4", runtime: false}
    ]
  end
end
