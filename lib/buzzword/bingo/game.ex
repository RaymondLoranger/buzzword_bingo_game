# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the course "Multi-Player Bingo" by Mike and Nicole Clark. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Buzzword.Bingo.Game do
  @moduledoc """
  Creates a `game` struct for the _Multi-Player Bingo_ game.
  Also marks the square having a given `phrase` for a given `player`.

  ##### Based on the course [Multi-Player Bingo](https://pragmaticstudio.com/courses/unpacked-bingo) by Mike and Nicole Clark.
  """

  use PersistConfig

  alias __MODULE__
  alias __MODULE__.Checker
  alias Buzzword.Bingo.{Player, Square}
  alias Buzzword.Cache

  @enforce_keys [:name, :size, :squares]
  defstruct name: nil, size: nil, squares: nil, scores: %{}, winner: nil

  @type t :: %Game{
          name: String.t(),
          size: pos_integer,
          squares: [Square.t()],
          scores: %{Player.t() => {pos_integer, pos_integer}},
          winner: Player.t() | nil
        }

  @pmark_th_sz get_env(:parallel_marking_threshold_size)
  @size_range get_env(:size_range)

  @doc """
  Creates a `game` with a flat list of `size` x `size` squares created
  from the given map or list of `buzzwords` of the form `{phrase, points}`.
  """
  @spec new(String.t(), pos_integer, map | list) :: t | {:error, atom}
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
  Marks the square having the given `phrase` for the given `player`,
  updates the scores, and checks for a bingo!
  """
  @spec mark_square(t, String.t(), Player.t()) :: t
  def mark_square(%Game{winner: nil} = game, phrase, %Player{} = player)
      when is_binary(phrase) do
    game
    |> update_squares(phrase, player, game.size > @pmark_th_sz)
    |> update_scores()
    |> assign_winner_if_bingo(phrase, player)
  end

  def mark_square(game, _phrase, _player), do: game

  ## Private functions

  @spec update_squares(t, String.t(), Player.t(), boolean) :: t
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
    scores =
      game.squares
      |> Enum.reject(&is_nil(&1.marked_by))
      |> Enum.map(fn square -> {square.marked_by, square.points} end)
      |> Enum.reduce(%{}, fn {player, points}, scores ->
        Map.update(scores, player, {points, 1}, &inc(&1, points))
      end)

    put_in(game.scores, scores)
  end

  @spec inc(tuple, pos_integer) :: {pos_integer, pos_integer}
  defp inc({score, marked}, points), do: {score + points, marked + 1}

  @spec assign_winner_if_bingo(t, String.t(), Player.t()) :: t
  defp assign_winner_if_bingo(game, phrase, player) do
    if Checker.bingo?(game, phrase, player),
      do: put_in(game.winner, player),
      else: game
  end
end
