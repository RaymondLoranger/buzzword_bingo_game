defmodule Buzzword.Bingo.GameTest do
  use ExUnit.Case, async: true

  alias Buzzword.Bingo.{Game, Player, Square}

  doctest Game

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
      %Game{} = game = Game.mark(games.new_game, "A1", players.joe)

      assert Enum.at(game.squares, 0) == %Square{
               phrase: "A1",
               points: 101,
               marked_by: players.joe
             }
    end

    test "keeps marked square as is", %{games: games, players: players} do
      %Game{} = game = Game.mark(games.new_game, "A3", players.jim)
      assert ^game = Game.mark(game, "A3", players.joe)

      assert Enum.at(game.squares, 2) == %Square{
               phrase: "A3",
               points: 103,
               marked_by: players.jim
             }
    end

    test "returns a won game as is", %{games: games, players: players} do
      won_game = games.won_game
      assert ^won_game = Game.mark(won_game, "A2", players.joe)
    end

    test "scores of a won game", %{games: games, players: players} do
      assert games.won_game.scores == %{
               players.joe => {606, 3},
               players.jim => {404, 2}
             }
    end

    test "winner of a won game", %{games: games, players: players} do
      assert games.won_game.winner == players.joe
    end
  end
end
