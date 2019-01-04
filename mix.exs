defmodule Buzzword.Bingo.Game.MixProject do
  use Mix.Project

  def project do
    [
      app: :buzzword_bingo_game,
      version: "0.1.1",
      elixir: "~> 1.7",
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
      {:mix_tasks,
       github: "RaymondLoranger/mix_tasks", only: :dev, runtime: false},
      {:persist_config, "~> 0.1"},
      {:buzzword_cache, path: "../buzzword_cache"},
      {:buzzword_bingo_player, path: "../buzzword_bingo_player"},
      {:buzzword_bingo_square, path: "../buzzword_bingo_square"},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end
end
