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
      |> Game.mark_square("A1", joe)
      |> Game.mark_square("A3", jim)
      |> Game.mark_square("B2", joe)
      |> Game.mark_square("C1", jim)
      |> Game.mark_square("C3", joe)

    games = %{new_game: new_game, won_game: won_game}
    players = %{joe: joe, jim: jim}

    poison =
      ~s<{"winner":{"name":"Joe","color":"light_blue"},"squares":[{"points":101,"phrase":"A1","marked_by":{"name":"Joe","color":"light_blue"}},{"points":102,"phrase":"A2","marked_by":null},{"points":103,"phrase":"A3","marked_by":{"name":"Jim","color":"light_cyan"}},{"points":201,"phrase":"B1","marked_by":null},{"points":202,"phrase":"B2","marked_by":{"name":"Joe","color":"light_blue"}},{"points":203,"phrase":"B3","marked_by":null},{"points":301,"phrase":"C1","marked_by":{"name":"Jim","color":"light_cyan"}},{"points":302,"phrase":"C2","marked_by":null},{"points":303,"phrase":"C3","marked_by":{"name":"Joe","color":"light_blue"}}],"size":3,"scores\":{"%Buzzword.Bingo.Player{color: \\"light_cyan\\", name: \\"Jim\\"}":[404,2],"%Buzzword.Bingo.Player{color: \\"light_blue\\", name: \\"Joe\\"}":[606,3]},"name":"won-game"}>

    jason =
      ~s<{"name":"won-game","scores":{"%Buzzword.Bingo.Player{color: \\"light_blue\\", name: \\"Joe\\"}":[606,3],"%Buzzword.Bingo.Player{color: \\"light_cyan\\", name: \\"Jim\\"}":[404,2]},"size":3,"squares":[{"marked_by":{"color":"light_blue","name":"Joe"},"phrase":"A1","points":101},{"marked_by":null,"phrase":"A2","points":102},{"marked_by":{"color":"light_cyan","name":"Jim"},"phrase":"A3","points":103},{"marked_by":null,"phrase":"B1","points":201},{"marked_by":{"color":"light_blue","name":"Joe"},"phrase":"B2","points":202},{"marked_by":null,"phrase":"B3","points":203},{"marked_by":{"color":"light_cyan","name":"Jim"},"phrase":"C1","points":301},{"marked_by":null,"phrase":"C2","points":302},{"marked_by":{"color":"light_blue","name":"Joe"},"phrase":"C3","points":303}],"winner":{"color":"light_blue","name":"Joe"}}>

    decoded = %{
      "name" => "won-game",
      "scores" => %{
        "%Buzzword.Bingo.Player{color: \"light_blue\", name: \"Joe\"}" => [
          606,
          3
        ],
        "%Buzzword.Bingo.Player{color: \"light_cyan\", name: \"Jim\"}" => [
          404,
          2
        ]
      },
      "size" => 3,
      "squares" => [
        %{
          "marked_by" => %{"color" => "light_blue", "name" => "Joe"},
          "phrase" => "A1",
          "points" => 101
        },
        %{"marked_by" => nil, "phrase" => "A2", "points" => 102},
        %{
          "marked_by" => %{"color" => "light_cyan", "name" => "Jim"},
          "phrase" => "A3",
          "points" => 103
        },
        %{"marked_by" => nil, "phrase" => "B1", "points" => 201},
        %{
          "marked_by" => %{"color" => "light_blue", "name" => "Joe"},
          "phrase" => "B2",
          "points" => 202
        },
        %{"marked_by" => nil, "phrase" => "B3", "points" => 203},
        %{
          "marked_by" => %{"color" => "light_cyan", "name" => "Jim"},
          "phrase" => "C1",
          "points" => 301
        },
        %{"marked_by" => nil, "phrase" => "C2", "points" => 302},
        %{
          "marked_by" => %{"color" => "light_blue", "name" => "Joe"},
          "phrase" => "C3",
          "points" => 303
        }
      ],
      "winner" => %{"color" => "light_blue", "name" => "Joe"}
    }

    %{
      games: games,
      players: players,
      json: %{poison: poison, jason: jason, decoded: decoded}
    }
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
      %Game{} = game = Game.mark_square(games.new_game, "A1", players.joe)

      assert Enum.at(game.squares, 0) == %Square{
               phrase: "A1",
               points: 101,
               marked_by: players.joe
             }
    end

    test "keeps marked square as is", %{games: games, players: players} do
      %Game{} = game = Game.mark_square(games.new_game, "A3", players.jim)
      assert ^game = Game.mark_square(game, "A3", players.joe)

      assert Enum.at(game.squares, 2) == %Square{
               phrase: "A3",
               points: 103,
               marked_by: players.jim
             }
    end

    test "returns a won game as is", %{games: games, players: players} do
      won_game = games.won_game
      assert ^won_game = Game.mark_square(won_game, "A2", players.joe)
    end

    test "updates scores of a won game", %{games: games, players: players} do
      assert games.won_game.scores == %{
               players.joe => {606, 3},
               players.jim => {404, 2}
             }
    end

    test "assigns winner of a won game", %{games: games, players: players} do
      assert games.won_game.winner == players.joe
    end

    test "can be encoded by Poison", %{games: games, json: json} do
      assert Poison.encode!(games.won_game) == json.poison
      assert Poison.decode!(json.poison) == json.decoded
    end

    test "can be encoded by Jason", %{games: games, json: json} do
      assert Jason.encode!(games.won_game) == json.jason
      assert Jason.decode!(json.jason) == json.decoded
    end
  end
end
