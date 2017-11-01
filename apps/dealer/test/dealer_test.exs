defmodule DealerTest do
  use ExUnit.Case
  doctest Dealer

  test "greets the world" do
    assert Dealer.hello() == :world
  end
end
