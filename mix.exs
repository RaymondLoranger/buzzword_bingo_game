defmodule Buzzword.Bingo.Game.MixProject do
  use Mix.Project

  def project do
    [
      app: :buzzword_bingo_game,
      version: "0.1.16",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:buzzword_bingo_player, github: "RaymondLoranger/buzzword_bingo_player"},
      {:buzzword_bingo_square, github: "RaymondLoranger/buzzword_bingo_square"},
      {:buzzword_cache, github: "RaymondLoranger/buzzword_cache"},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:persist_config, "~> 0.4", runtime: false}
    ]
  end
end
