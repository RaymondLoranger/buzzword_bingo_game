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
  @spec bingo_line?(line, [Square.t()], Player.t()) :: boolean
  defp bingo_line?(indexes, squares, player) do
    player ==
      indexes
      |> Stream.map(&Enum.at(squares, &1).marked_by)
      |> Enum.find(player, &(&1 != player))
  end

  # Find the index of the square containing `phrase`.
  @spec index([Square.t()], Square.phrase()) :: index | nil
  defp index(squares, phrase),
    do: Enum.find_index(squares, &(&1.phrase == phrase))

  @spec main_diag(Game.size()) :: line
  defp main_diag(size), do: 0..(size * size - 1)//(size + 1)

  @spec anti_diag(Game.size()) :: line
  defp anti_diag(size), do: (size - 1)..(size * size - size)//(size - 1)

  @spec row(Game.size(), index) :: line
  defp row(size, index) do
    row = div(index, size)
    (row * size)..(row * size + size - 1)
  end

  @spec col(Game.size(), index) :: line
  defp col(size, index) do
    col = rem(index, size)
    col..(size * size - size + col)//size
  end
end
