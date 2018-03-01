defmodule Casino.TableTest do
  use ExUnit.Case

  alias Casino.Table

  test "who won!" do
    assert :dealer_bust == Table.who_won(22, 1)
    assert :player_bust == Table.who_won(1, 22)
    assert :player_win == Table.who_won(1, 21)
    assert :push == Table.who_won(1, 1)
    assert :dealer_win == Table.who_won(2, 1)
  end

  test "hit or stay" do
    cards = []

    assert [] == Table.hit_or_stay(:stay, cards, self())
    assert [] == Table.hit_or_stay(:bust, cards, self())
  end
end
