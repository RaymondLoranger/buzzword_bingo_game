# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the course "Multi-Player Bingo" by Mike and Nicole Clark. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Buzzword.Bingo.Game do
  @moduledoc """
  A game struct and functions for the _Multi-Player Bingo_ game.

  The game struct contains the fields `name`, `size`, `squares`, `scores` and
  `winner` representing the characteristics of a game in the _Multi-Player
  Bingo_ game.

  ##### Based on the course [Multi-Player Bingo](https://pragmaticstudio.com/courses/unpacked-bingo) by Mike and Nicole Clark.
  """

  use PersistConfig

  alias __MODULE__
  alias __MODULE__.Checker
  alias Buzzword.Bingo.{Player, Square}
  alias Buzzword.Cache

  @adjectives get_env(:haiku_adjectives)
  @nouns get_env(:haiku_nouns)
  @pmark_th_sz get_env(:parallel_marking_threshold_size)
  @size_range get_env(:size_range)

  @derive [Poison.Encoder]
  @derive Jason.Encoder
  @enforce_keys [:name, :size, :squares]
  defstruct name: nil, size: nil, squares: nil, scores: %{}, winner: nil

  @typedoc "A tuple of player and player score"
  @type game_score :: {Player.t(), player_score}
  @typedoc "A map assigning a player score to a player"
  @type game_scores :: %{Player.t() => player_score}
  @typedoc "Number of marked squares"
  @type marked_count :: pos_integer
  @typedoc "Game name"
  @type name :: String.t()
  @typedoc "A tuple of total points and number of marked squares"
  @type player_score :: {points_sum, marked_count}
  @typedoc "Total points"
  @type points_sum :: pos_integer
  @typedoc "Game size"
  @type size :: pos_integer
  @typedoc "A game struct for the Multi-Player Bingo game"
  @type t :: %Game{
          name: name,
          size: size,
          squares: [Square.t()],
          scores: game_scores,
          winner: Player.t() | nil
        }

  @doc """
  Creates a game struct with a list of `size` x `size` buzzwords randomly taken
  from the given map or a list of `buzzwords` of the form `{phrase, points}`.
  """
  @spec new(name, size, Cache.buzzwords() | [Cache.buzzword()]) ::
          t | {:error, atom}
  def new(name, size, buzzwords \\ Cache.get_buzzwords())

  def new(name, size, buzzwords)
      when is_binary(name) and size in @size_range and is_map(buzzwords) and
             map_size(buzzwords) >= size * size do
    new(name, size, Enum.take_random(buzzwords, size * size))
  end

  def new(name, size, buzzwords)
      when is_binary(name) and size in @size_range and is_list(buzzwords) and
             length(buzzwords) == size * size do
    %Game{name: name, size: size, squares: Enum.map(buzzwords, &Square.new/1)}
  end

  def new(_name, _size, _buzzwords), do: {:error, :invalid_game_args}

  @doc """
  Marks the square having the given `phrase` with the given `player`,
  updates the scores, and checks for a bingo!
  """
  @spec mark_square(t, Square.phrase(), Player.t()) :: t
  def mark_square(%Game{winner: nil} = game, phrase, %Player{} = player)
      when is_binary(phrase) do
    game
    |> update_squares(phrase, player, game.size > @pmark_th_sz)
    |> update_scores()
    |> assign_winner_if_bingo(phrase, player)
  end

  def mark_square(game, _phrase, _player), do: game

  @doc """
  Generates a unique, URL-friendly name such as "bold-frog-8249".
  """
  @spec haiku_name :: name
  def haiku_name do
    [Enum.random(@adjectives), Enum.random(@nouns), :rand.uniform(9999)]
    |> Enum.join("-")
  end

  ## Private functions

  @spec update_squares(t, Square.phrase(), Player.t(), boolean) :: t
  defp update_squares(game, phrase, player, false = _pmark?) do
    squares = Enum.map(game.squares, &Square.mark(&1, phrase, player))
    put_in(game.squares, squares)
  end

  defp update_squares(game, phrase, player, true = _pmark?) do
    squares = pmap(game.squares, &Square.mark(&1, phrase, player))
    put_in(game.squares, squares)
  end

  @spec pmap(Enum.t(), (any -> any)) :: list
  defp pmap(enum, fun) do
    enum
    |> Enum.map(&Task.async(fn -> fun.(&1) end))
    |> Enum.map(&Task.await/1)
  end

  @spec update_scores(t) :: t
  defp update_scores(game) do
    game_scores =
      Enum.reject(game.squares, &is_nil(&1.marked_by))
      |> Enum.reduce(
        %{},
        fn %Square{marked_by: player, points: points}, game_scores ->
          Map.update(game_scores, player, {points, 1}, &inc(&1, points))
        end
      )

    put_in(game.scores, game_scores)
  end

  @spec inc(player_score, Square.points()) :: player_score
  defp inc({score, marked}, points), do: {score + points, marked + 1}

  @spec assign_winner_if_bingo(t, Square.phrase(), Player.t()) :: t
  defp assign_winner_if_bingo(game, phrase, player) do
    if Checker.bingo?(game, phrase, player),
      do: put_in(game.winner, player),
      else: game
  end
end
