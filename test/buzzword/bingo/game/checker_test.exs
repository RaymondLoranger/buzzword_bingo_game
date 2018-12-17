defmodule Buzzword.Bingo.Game.CheckerTest do
  use ExUnit.Case, async: true

  alias Buzzword.Bingo.{Game, Player}
  alias Buzzword.Bingo.Game.Checker

  doctest Checker

  setup_all do
    joe = Player.new("Joe", "light_blue")
    jim = Player.new("Jim", "light_cyan")

    game = fn name ->
      Game.new(name, 3, [
        {"A1", 101},
        {"A2", 102},
        {"A3", 103},
        {"B1", 201},
        {"B2", 202},
        {"B3", 203},
        {"C1", 301},
        {"C2", 302},
        {"C3", 303}
      ])
    end

    new_game = game.("new-game")

    won_game =
      game.("won-game")
      |> Game.mark("A1", joe)
      |> Game.mark("A3", jim)
      |> Game.mark("B2", joe)
      |> Game.mark("C1", jim)
      |> Game.mark("C3", joe)

    games = %{new_game: new_game, won_game: won_game}
    players = %{joe: joe, jim: jim}
    {:ok, games: games, players: players}
  end

  describe "Checker.bingo?/3" do
    test "returns true", %{games: games, players: players} do
      assert Checker.bingo?(games.won_game, "A1", players.joe)

      game =
        games.new_game
        |> Game.mark("A1", players.jim)
        |> Game.mark("A2", players.jim)
        |> Game.mark("A3", players.jim)

      assert Checker.bingo?(game, "A3", players.jim)
    end

    test "returns false", %{games: games, players: players} do
      refute Checker.bingo?(games.new_game, "A1", players.joe)
      refute Checker.bingo?(games.won_game, "A3", players.jim)
    end

    test "returns false if bad phrase", %{games: games, players: players} do
      assert Checker.bingo?(games.won_game, "A1", players.joe)
      refute Checker.bingo?(games.won_game, "a1", players.joe)
    end
  end
end
