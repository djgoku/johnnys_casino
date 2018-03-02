defmodule Casino do
  @moduledoc """
  Documentation for Casino.
  """
  def sum_hand(hand) do
    aces =
      Enum.filter(hand, fn card ->
        {_, rank, _, _} = card
        rank == "A"
      end)

    if aces == [] do
      calculate_sum(hand)
    else
      first = List.first(aces)

      new_hand = List.delete(hand, first)

      new_hands =
        for card <- [11, 1] do
          temp_card = {"", "", "", [card]}
          temp_hand = [temp_card] ++ new_hand
          calculate_sum(temp_hand)
        end

      List.flatten(new_hands)
    end
  end

  defp calculate_sum(hand) do
    result =
      Enum.map(hand, fn card ->
        {_, _, _, values} = card

        new_values =
          if length(values) == 2 do
            List.first(values)
          else
            values
          end

        new_values
      end)

    new_result =
      result
      |> List.flatten()
      |> Enum.sum()

    [new_result]
  end

  def permutations([]), do: [[]]

  def permutations(list),
    do:
      for(
        elem <- list,
        rest <- permutations(list -- [elem]),
        do: [elem | rest]
      )
end
