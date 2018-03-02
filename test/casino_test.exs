defmodule CasinoTest do
  use ExUnit.Case

  test "sum hand" do
    assert Casino.sum_hand([{:spades, "3", 127_139, [3]}, {:spades, "J", 127_147, [10]}]) == [13]

    assert Casino.sum_hand([{:diamonds, "A", 127_169, [1, 11]}, {:hearts, "9", 127_161, '\t'}]) ==
             [20, 10]

    assert Casino.sum_hand([
             {:diamonds, "A", 127_169, [1, 11]},
             {:hearts, "9", 127_161, '\t'},
             {:diamonds, "A", 127_169, [1, 11]}
           ]) == [21, 11]
  end
end
