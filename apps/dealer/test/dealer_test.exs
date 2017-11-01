defmodule DealerTest do
  use ExUnit.Case

  test "player can join table" do
    state = %{players: [], max_players: 7}
    {:reply, reply, new_state} = Dealer.handle_call(:join, {:pid, :term}, state)

    assert reply == {:player, 1}
    assert new_state[:players] == [:pid]
  end

  test "player gets error when trying to rejoin table" do
    state = %{players: [], max_players: 7}
    {:reply, reply, new_state} = Dealer.handle_call(:join, {:pid, :term}, state)

    assert reply == {:player, 1}
    assert new_state[:players] == [:pid]

    {:reply, reply, new_state} = Dealer.handle_call(:join, {:pid, :term}, new_state)

    assert reply == {:error, :already_joined_table}
    assert new_state[:players] == [:pid]
  end

  test "player is unable to join a full table" do
    state = %{players: [:not_test_pid], max_players: 1}
    {:reply, reply, new_state} = Dealer.handle_call(:join, {:pid, :term}, state)

    assert reply == {:error, :max_players_at_table}
    assert new_state[:players] == [:not_test_pid]
  end
end
