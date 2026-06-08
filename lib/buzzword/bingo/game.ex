# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the course "Multi-Player Bingo" by Mike and Nicole Clark. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Buzzword.Bingo.Game do
  @moduledoc """
  A game struct and functions for the _Multi-Player Buzzword Bingo_ game.

  The game struct contains the fields:

    - `name`
    - `size`
    - `squares`
    - `scores`
    - `winner`

  representing the properties of a game in the _Multi-Player Buzzword Bingo_
  game.

  ##### Based on the course [Multi-Player Bingo](https://pragmaticstudio.com/courses/unpacked-bingo) by Mike and Nicole Clark.
  """

  use PersistConfig

  alias __MODULE__
  alias __MODULE__.Checker
  alias Buzzword.Bingo.{Player, Square}
  alias Buzzword.Cache

  @adjectives get_env(:haiku_adjectives)
  @nouns get_env(:haiku_nouns)
  @pmark_thld_size get_env(:parallel_marking_threshold_size)
  @size_range get_env(:size_range)

  @enforce_keys [:name, :size, :squares]
  defstruct name: nil, size: nil, squares: nil, scores: %{}, winner: nil

  @typedoc "Number of marked squares"
  @type marked_count :: pos_integer
  @typedoc "Game name"
  @type name :: String.t()
  @typedoc "A tuple of total points and number of marked squares"
  @type player_score :: {points_sum, marked_count}
  @typedoc "Total points"
  @type points_sum :: pos_integer
  @typedoc "A map assigning a player score to a player"
  @type scores :: %{Player.t() => player_score}
  @typedoc "Game size"
  @type size :: pos_integer
  @typedoc "A game struct for the Multi-Player Buzzword Bingo game"
  @type t :: %Game{
          name: name,
          size: size,
          squares: [Square.t()],
          scores: scores,
          winner: Player.t() | nil
        }

  @doc """
  Creates a game struct with `size` x `size` random buzzwords from `buzzwords`.
  The default value for `buzzwords` is provided by function
  `Buzzword.Cache.get_buzzwords/0`.
  """
  @spec new(name, size, Cache.buzzwords() | [Cache.buzzword()]) ::
          t | {:error, atom}
  def new(name, size, buzzwords \\ Buzzword.Cache.get_buzzwords())

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
  updates the scores, and assigns the bingo winner, if any.
  """
  @spec mark_square(t, Square.phrase(), Player.t()) :: t
  def mark_square(
        %Game{size: size, scores: scores, winner: nil} = game,
        phrase,
        %Player{} = player
      )
      when is_binary(phrase) do
    game
    |> update_squares(phrase, player, size > @pmark_thld_size)
    |> update_scores()
    |> assign_winner(phrase, player, scores)
  end

  def mark_square(game, _phrase, _player) do
    game
  end

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
  defp update_squares(
         %Game{squares: squares} = game,
         phrase,
         player,
         _pmark? = false
       ) do
    squares
    |> Enum.map(&Square.mark(&1, phrase, player))
    |> then(&put_in(game.squares, &1))
  end

  defp update_squares(
         %Game{squares: squares} = game,
         phrase,
         player,
         _pmark?
       ) do
    squares
    |> pmap(&Square.mark(&1, phrase, player))
    |> then(&put_in(game.squares, &1))
  end

  @spec pmap([Square.t()], (Square.t() -> Square.t())) :: [Square.t()]
  defp pmap(squares, mark_fun) do
    squares
    |> Enum.map(&Task.async(fn -> mark_fun.(&1) end))
    |> Enum.map(&Task.await/1)
  end

  @spec update_scores(t) :: t
  defp update_scores(%Game{squares: squares} = game) do
    for %Square{marked_by: player, points: points} <- squares,
        player != nil,
        reduce: %{} do
      scores -> Map.update(scores, player, {points, 1}, &inc(&1, points))
    end
    |> then(&put_in(game.scores, &1))
  end

  @spec inc(player_score, Square.points()) :: player_score
  defp inc({sum, count}, points), do: {sum + points, count + 1}

  # Scores didn't change, so no bingo possible.
  @spec assign_winner(t, Square.phrase(), Player.t(), scores) :: t
  defp assign_winner(%Game{scores: scores} = game, _phrase, _player, scores) do
    game
  end

  # Scores changed, so a square was marked.
  defp assign_winner(game, phrase, player, _scores) do
    game
    |> Checker.bingo?(phrase, player)
    |> assign_winner(game, player)
  end

  @spec assign_winner(boolean, t, Player.t()) :: t
  defp assign_winner(_bingo? = false, game, _player), do: game
  defp assign_winner(_bingo?, game, player), do: put_in(game.winner, player)
end
