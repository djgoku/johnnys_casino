defmodule Casino.Player.DealerTest do
  use ExUnit.Case

  alias Casino.Player.Dealer

  test "hit or stay" do
    hand = %{current_hand: [{:spades, "3", 127_139, [3]}, {:spades, "J", 127_147, [10]}]}
    assert {:reply, :hit, hand} == Dealer.handle_call(:hit_or_stay, :from, hand)

    hand = %{current_hand: [{:spades, "6", 127_142, [6]}, {:diamonds, "A", 127_169, [1, 11]}]}
    assert {:reply, :hit, hand} == Dealer.handle_call(:hit_or_stay, :from, hand)

    hand = %{current_hand: [{:hearts, "9", 127_161, '\t'}, {:spades, "J", 127_147, [10]}]}
    assert {:reply, :stay, hand} == Dealer.handle_call(:hit_or_stay, :from, hand)

    hand = %{
      current_hand: [
        {:diamonds, "2", 127_170, [2]},
        {:diamonds, "8", 127_176, [8]},
        {:diamonds, "5", 127_173, [5]},
        {:spades, "A", 127_137, [1, 11]}
      ]
    }

    assert {:reply, :hit, hand} == Dealer.handle_call(:hit_or_stay, :from, hand)
  end
end
