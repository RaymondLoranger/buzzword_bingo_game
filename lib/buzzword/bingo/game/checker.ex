defmodule Buzzword.Bingo.Game.Checker do
  @moduledoc """
  Checks for a bingo!
  """

  alias Buzzword.Bingo.{Game, Player, Square}

  @type index :: non_neg_integer

  @doc """
  Checks the flat list of `size` x `size` `squares` of the given `game`.
  Returns `true` if all the `squares` of a line (row, column or diagonal)
  containing the given `phrase` have been marked by the given `player`.
  Returns `false` otherwise or when the given `phrase` cannot be found.
  We use lists of `size` indexes to represent the lines to be checked.
  """
  @spec bingo?(Game.t(), Square.phrase(), Player.t()) :: boolean
  def bingo?(
        %Game{size: size, squares: squares} = _game,
        phrase,
        %Player{} = player
      )
      when is_binary(phrase) do
    with index when is_integer(index) <- index(squares, phrase),
         false <- row(size, index) |> line_bingo?(squares, player),
         false <- col(size, index) |> line_bingo?(squares, player),
         false <- main_diag(size) |> line_bingo?(index, squares, player) do
      anti_diag(size) |> line_bingo?(index, squares, player)
    else
      nil -> false
      true -> true
    end
  end

  ## Private functions

  @spec line_bingo?([index], index, [Square.t()], Player.t()) :: boolean
  defp line_bingo?(indexes, index, squares, player),
    do: index in indexes and line_bingo?(indexes, squares, player)

  @spec line_bingo?([index], [Square.t()], Player.t()) :: boolean
  defp line_bingo?(indexes, squares, player) do
    Enum.all?(indexes, fn index ->
      Enum.at(squares, index).marked_by == player
    end)
  end

  @spec index([Square.t()], Square.phrase()) :: index | nil
  defp index(squares, phrase),
    do: Enum.find_index(squares, fn square -> square.phrase == phrase end)

  @spec main_diag(Game.size()) :: [index]
  defp main_diag(size), do: Enum.take_every(0..(size * size - 1), size + 1)

  @spec anti_diag(Game.size()) :: [index]
  defp anti_diag(size),
    do: Enum.take_every((size - 1)..(size * size - size), size - 1)

  @spec row(Game.size(), index) :: [index]
  defp row(size, index) do
    row = div(index, size)
    Enum.to_list((row * size)..(row * size + size - 1))
  end

  @spec col(Game.size(), index) :: [index]
  defp col(size, index) do
    col = rem(index, size)
    Enum.take_every(col..(size * size - size + col), size)
  end
end
