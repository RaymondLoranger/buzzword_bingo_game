defmodule Buzzword.Bingo.Game.CheckerTest do
  use ExUnit.Case, async: true

  alias Buzzword.Bingo.{Game, Player, Square}
  alias Buzzword.Bingo.Game.Checker

  doctest Checker

  setup_all do
    joe = Player.new("Joe", "light_blue")
    jim = Player.new("Jim", "light_cyan")

    virgin_squares = [
      Square.new("A1", 101),
      Square.new("A2", 102),
      Square.new("A3", 103),
      Square.new("B1", 201),
      Square.new("B2", 202),
      Square.new("B3", 203),
      Square.new("C1", 301),
      Square.new("C2", 302),
      Square.new("C3", 303)
    ]

    virgin_game = %Game{
      name: "virgin-game",
      size: 3,
      squares: virgin_squares,
      scores: %{},
      winner: nil
    }

    marked_squares = [
      %Square{phrase: "A1", points: 101, marked_by: joe},
      %Square{phrase: "A2", points: 102, marked_by: nil},
      %Square{phrase: "A3", points: 103, marked_by: jim},
      %Square{phrase: "B1", points: 201, marked_by: nil},
      %Square{phrase: "B2", points: 202, marked_by: joe},
      %Square{phrase: "B3", points: 203, marked_by: nil},
      %Square{phrase: "C1", points: 301, marked_by: jim},
      %Square{phrase: "C2", points: 302, marked_by: nil},
      %Square{phrase: "C3", points: 303, marked_by: joe}
    ]

    marked_game = %Game{
      name: "marked-game",
      size: 3,
      squares: marked_squares,
      scores: %{joe => 606, jim => 404},
      winner: joe
    }

    games = %{virgin: virgin_game, marked: marked_game}
    players = %{joe: joe, jim: jim}
    {:ok, games: games, players: players}
  end

  describe "Checker.bingo?/3" do
    test "returns true", %{games: games, players: players} do
      assert Checker.bingo?(games.marked, "A1", players.joe)

      game =
        games.virgin
        |> Game.mark("A1", players.jim)
        |> Game.mark("A2", players.jim)
        |> Game.mark("A3", players.jim)

      assert Checker.bingo?(game, "A3", players.jim)
    end

    test "returns false", %{games: games, players: players} do
      refute Checker.bingo?(games.virgin, "A1", players.joe)
      refute Checker.bingo?(games.marked, "A3", players.jim)
    end

    test "returns false if bad phrase", %{games: games, players: players} do
      assert Checker.bingo?(games.marked, "A1", players.joe)
      refute Checker.bingo?(games.marked, "a1", players.joe)
    end
  end
end
