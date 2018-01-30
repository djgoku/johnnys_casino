defmodule Casino do
  @moduledoc """
  Documentation for Casino.
  """

    @doc """
    Sum hand(s).

    ## Examples

        iex> Casino.hello
        :world

    """
    def sum_hand(hand) do

      aces = Enum.filter(hand, fn(card) ->
        {_, rank, _, _} = card
        rank == "A"
      end)

      result = Enum.map(hand, fn(card) ->
        {_, _, _, values} = card
        values
      end)

      result
      |> List.flatten
      |> Enum.sum
    end

    def permutations([]), do: [[]]
    def permutations(list), do: for elem <- list, rest <- permutations(list--[elem]), do: [elem|rest]
end