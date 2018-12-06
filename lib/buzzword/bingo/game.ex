# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the course "Multi-Player Bingo" by Mike and Nicole Clark. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Buzzword.Bingo.Game do
  use PersistConfig

  @course_ref Application.get_env(@app, :course_ref)

  @moduledoc """
  Creates a `game` struct.
  Also marks the square having a given `phrase` for a given `player`.
  \n##### #{@course_ref}
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
          scores: %{Player.t() => pos_integer},
          winner: Player.t() | nil
        }

  @size_range Application.get_env(@app, :size_range)

  @doc """
  Creates a `game` with a flat list of `size` x `size` squares
  taken randomly from the given map of `buzzwords` where
  each buzzword is of the form `{phrase, points}`.
  """
  @spec new(String.t(), pos_integer, map) :: t | {:error, atom}
  def new(name, size, buzzwords \\ Cache.get_buzzwords())

  def new(name, size, %{} = buzzwords)
      when is_binary(name) and size in @size_range do
    squares =
      buzzwords
      |> Enum.take_random(size * size)
      |> Enum.map(&Square.new/1)

    %Game{name: name, size: size, squares: squares}
  end

  def new(_name, _size, _buzzwords), do: {:error, :invalid_game_args}

  @doc """
  Marks the square having the given `phrase` for the given `player`,
  updates the scores, and checks for a bingo!
  """
  @spec mark(t, String.t(), Player.t()) :: t
  def mark(%Game{winner: nil} = game, phrase, %Player{} = player)
      when is_binary(phrase) do
    game
    |> update_squares(phrase, player)
    |> update_scores()
    |> assign_winner_if_bingo(phrase, player)
  end

  def mark(game, _phrase, _player), do: game

  ## Private functions

  @spec update_squares(t, String.t(), Player.t()) :: t
  defp update_squares(game, phrase, player) do
    squares = Enum.map(game.squares, &Square.mark(&1, phrase, player))
    put_in(game.squares, squares)
  end

  @spec update_scores(t) :: t
  defp update_scores(game) do
    scores =
      game.squares
      |> Stream.reject(&is_nil(&1.marked_by))
      |> Stream.map(fn square -> {square.marked_by, square.points} end)
      |> Enum.reduce(%{}, fn {player, points}, scores ->
        Map.update(scores, player, points, &(&1 + points))
      end)

    put_in(game.scores, scores)
  end

  @spec assign_winner_if_bingo(t, String.t(), Player.t()) :: t
  defp assign_winner_if_bingo(game, phrase, player) do
    if Checker.bingo?(game, phrase, player),
      do: put_in(game.winner, player),
      else: game
  end
end
