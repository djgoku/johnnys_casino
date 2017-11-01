defmodule Dealer do
  @moduledoc """
  A dealer controls all aspects of a table at johnny's casino.
  """

  use GenServer
  require Logger


  # Client

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:ok, %{players: [], max_players: 7}}
  end

  @doc """
  Join a casino table.

  ## Examples

      # Number returned is position at table
      iex> Dealer.join()
      {:player, 1}

      # error trying to re-join table
      iex> Dealer.join()
      {:error, :already_joined_table}

      # error max players at table
      iex> Dealer.join()
      {:error, :max_players_at_table}
  """
  @spec join() :: {:ok, {:player_number, pos_integer()}} | {:error, any()}
  def join() do
    GenServer.call(__MODULE__, :join)
  end

  # Server

  def handle_call(:join, {pid, _term}, state) do
    Logger.debug("(Dealer) received join from #{inspect pid}")

    max_players = state[:max_players]
    current_players = state[:players]

    case length(current_players) do
      x when x < max_players ->
        if Enum.member?(current_players, pid) do
          {:reply, {:error, :already_joined_table}, state}
        else
          all_players = current_players ++ [pid]
          {:reply, {:player, length(all_players)}, %{state | players: all_players}}
        end
      _ ->
        {:reply, {:error, :max_players_at_table}, state}
    end
  end
end
