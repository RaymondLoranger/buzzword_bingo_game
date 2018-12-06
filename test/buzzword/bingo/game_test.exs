defmodule Buzzword.Bingo.GameTest do
  use ExUnit.Case, async: true

  alias Buzzword.Bingo.{Game, Player, Square}

  doctest Game

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

    virgin = %Game{
      name: "virgin",
      size: 3,
      squares: virgin_squares,
      winner: nil
    }

    marked = %Game{
      name: "marked",
      size: 3,
      squares: marked_squares,
      winner: joe
    }

    games = %{virgin: virgin, marked: marked}
    players = %{joe: joe, jim: jim}
    {:ok, games: games, players: players}
  end

  describe "Game.new/3" do
    test "returns a struct" do
      assert %Game{
               name: "icy-moon",
               size: 4,
               squares: squares,
               scores: %{},
               winner: nil
             } = Game.new("icy-moon", 4)

      assert is_list(squares) and length(squares) == 4 * 4
    end

    test "returns a struct in a `with` macro" do
      assert(
        %Game{name: "dark-sun", size: 5, scores: %{}, winner: nil} =
          with %Game{} = game <- Game.new("dark-sun", 5) do
            game
          end
      )
    end

    test "returns a tuple" do
      assert Game.new("bad", 6) == {:error, :invalid_game_args}
      assert Game.new('bad', 3) == {:error, :invalid_game_args}
    end

    test "returns a tuple in a `with` macro" do
      assert(
        with %Game{} = game <- Game.new("bad", 2) do
          game
        else
          error -> error
        end == {:error, :invalid_game_args}
      )
    end
  end

  describe "Game.mark/3" do
    test "marks a virgin square", %{games: games, players: players} do
      %Game{} = game = Game.mark(games.virgin, "A1", players.joe)

      assert Enum.at(game.squares, 0) == %Square{
               phrase: "A1",
               points: 101,
               marked_by: players.joe
             }
    end

    test "keeps marked square as is", %{games: games, players: players} do
      marked_square = Enum.at(games.marked.squares, 2)
      %Game{} = game = Game.mark(games.marked, "A3", players.joe)
      assert ^marked_square = Enum.at(game.squares, 2)

      assert Enum.at(game.squares, 2) == %Square{
               phrase: "A3",
               points: 103,
               marked_by: players.jim
             }
    end

    test "returns a won game as is", %{games: games, players: players} do
      marked_game = games.marked
      assert ^marked_game = Game.mark(marked_game, "A2", players.joe)
    end
  end
end
