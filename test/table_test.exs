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
end
