defmodule Buzzword.Bingo.Game.Checker do
  @moduledoc """
  Checks for a bingo!
  """

  alias Buzzword.Bingo.{Game, Player, Square}

  @doc """
  Returns `true` if all the squares of a line (row, column or diagonal)
  containing the given `phrase` have been marked by the given `player`.
  Returns `false` otherwise or when the given `phrase` cannot be found.
  """
  @spec bingo?(Game.t(), Square.phrase(), Player.t()) :: boolean
  def bingo?(
        %Game{size: size, squares: squares} = _game,
        phrase,
        %Player{} = player
      )
      when is_binary(phrase) do
    # NOTE: Ranges of linear indexes represent the lines to be checked.
    with index when is_integer(index) <- index(squares, phrase),
         false <- row(size, index) |> bingo_line?(squares, player),
         false <- col(size, index) |> bingo_line?(squares, player),
         false <- main_diag(size) |> bingo_line?(squares, player) do
      anti_diag(size) |> bingo_line?(squares, player)
    else
      # No squares contain `phrase`...
      nil -> false
      # A bingo line was found...
      true -> true
    end
  end

  ## Private functions

  # Linear index
  @typep index :: non_neg_integer
  # Line (row, column or diagonal) of linear indexes
  @typep line :: Range.t()

  # Diagonal bingo? If so, the diagonal must contain the latest marked square.
  # Hence no need to confirm the marked square index is in the diagonal range.
  @spec bingo_line?(line, [Square.t()], Player.t()) :: boolean
  defp bingo_line?(indexes, squares, player) do
    for index <- indexes do
      Enum.at(squares, index).marked_by
    end
    |> Enum.all?(&(&1 == player))
  end

  # Find the index of the square containing `phrase`.
  @spec index([Square.t()], Square.phrase()) :: index | nil
  defp index(squares, phrase),
    do: Enum.find_index(squares, &(&1.phrase == phrase))

  @spec main_diag(Game.size()) :: line
  defp main_diag(size) do
    # 0 1 2
    # 3 4 5
    # 6 7 8
    # The range is 0..8//4.
    0..(size * size - 1)//(size + 1)
  end

  @spec anti_diag(Game.size()) :: line
  defp anti_diag(size) do
    # 0 1 2
    # 3 4 5
    # 6 7 8
    # The range is 2..6//2.
    (size - 1)..(size * size - size)//(size - 1)
  end

  @spec row(Game.size(), index) :: line
  defp row(size, index) do
    # 0 1 2
    # 3 4 5
    # 6 7 8
    # If index is 1, then row is 0 and the range is 0..2.
    # If index is 4, then row is 1 and the range is 3..5.
    # If index is 7, then row is 2 and the range is 6..8.
    row = div(index, size)
    (row * size)..(row * size + size - 1)
  end

  @spec col(Game.size(), index) :: line
  defp col(size, index) do
    # 0 1 2
    # 3 4 5
    # 6 7 8
    # If index is 3, then col is 0 and the range is 0..6//3.
    # If index is 4, then col is 1 and the range is 1..7//3.
    # If index is 5, then col is 2 and the range is 2..8//3.
    col = rem(index, size)
    col..(size * size - size + col)//size
  end
end
