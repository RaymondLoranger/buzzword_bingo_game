defmodule Buzzword.Bingo.Game.Checker do
  @moduledoc """
  Checks for a bingo!
  """

  alias Buzzword.Bingo.{Game, Player, Square}

  @type index :: non_neg_integer

  @doc """
  Checks the flat list of `size` x `size` `squares` of the given `game`.
  Returns `true` if all the `squares` of the row, column, or diagonal
  containing the given `phrase` have been marked by the given `player`.
  Otherwise `false` is returned.
  """
  @spec bingo?(Game.t(), String.t(), Player.t()) :: boolean
  def bingo?(
        %Game{size: size, squares: squares} = _game,
        phrase,
        %Player{} = player
      )
      when is_binary(phrase) do
    with index = index(squares, phrase),
         false <- size |> row(index) |> line_bingo?(squares, player),
         false <- size |> col(index) |> line_bingo?(squares, player),
         false <- size |> main_diag() |> line_bingo?(index, squares, player) do
      size |> anti_diag() |> line_bingo?(index, squares, player)
    else
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

  @spec index([Square.t()], String.t()) :: index
  defp index(squares, phrase),
    do: Enum.find_index(squares, fn square -> square.phrase == phrase end)

  @spec main_diag(pos_integer) :: [index]
  defp main_diag(size), do: Enum.take_every(0..(size * size - 1), size + 1)

  @spec anti_diag(pos_integer) :: [index]
  defp anti_diag(size),
    do: Enum.take_every((size - 1)..(size * size - size), size - 1)

  @spec row(pos_integer, index) :: [index]
  defp row(size, index) do
    row = div(index, size)
    Enum.to_list((row * size)..(row * size + size - 1))
  end

  @spec col(pos_integer, index) :: [index]
  defp col(size, index) do
    col = rem(index, size)
    Enum.take_every(col..(size * size - size + col), size)
  end
end
