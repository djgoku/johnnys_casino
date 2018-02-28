defmodule Casino.Player.DealerTest do
  use ExUnit.Case

  alias Casino.Player.Dealer

  test "hit or stay" do
    hand = %{current_hand: [{:spades, "3", 127139, [3]}, {:spades, "J", 127147, [10]}]}

    assert {:reply, :hit, hand} == Dealer.handle_call(:hit_or_stay, :from, hand)

    hand = %{current_hand: [{:spades, "6", 127142, [6]}, {:diamonds, "A", 127169, [1, 11]}]}

    assert {:reply, :hit, hand} == Dealer.handle_call(:hit_or_stay, :from, hand)

    hand = %{current_hand: [{:hearts, "9", 127161, '\t'}, {:spades, "J", 127147, [10]}]}

    assert {:reply, :stay, hand} == Dealer.handle_call(:hit_or_stay, :from, hand)
  end
end
