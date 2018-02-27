defmodule Casino.Table do
  @moduledoc """
  A table controls all aspects of a table at johnny's casino.
  """

  use GenServer
  require Logger


  # Client

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do

    send self(), :after_init

    {:ok, %{players: [], max_players: 7}}
  end

  @doc """
  Join a casino table.

  ## Examples

      # Number returned is position at table
      iex> Table.join()
      {:player, 1}

      # error trying to re-join table
      iex> Table.join()
      {:error, :already_joined_table}

      # error max players at table
      iex> Table.join()
      {:error, :max_players_at_table}
  """
  @spec join() :: {:ok, {:player, pos_integer()}} | {:error, any()}
  def join() do
    GenServer.call(__MODULE__, :join)
  end

  # Server

  def handle_call(:join, {pid, _term}, state) do
    Logger.debug("(Table) received join from #{inspect pid}")

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

  def handle_info(:after_init, state) do
    players = Casino.Table.get_players() ++ [Casino.Player.Table]

    if players <= state[:max_players] do
      Logger.info("(Casino.Table) starting a game with #{length(players)} of players")
      Enum.map(players, fn(player) ->
        spawn(player, :start_link, [[]])
      end)
    else
      Logger.error("(Casino.Table) unable to start game since max players met: #{inspect(players)}")
    end

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    players = state[:players]

    Enum.map(players, fn(player) ->
      card = get_card()
      send player, {:card, card}
    end)

    {:noreply, state}
  end

  defp get_card() do
    case ExCardDeck.get_card() do
      nil ->
        ExCardDeck.shuffle()
        ExCardDeck.get_card()
      card ->
        card
    end
  end

  def get_players() do
    table = Casino.Player.Table

    with {:ok, list} <- :application.get_key(:casino, :modules) do
      list
      |> Enum.filter(fn(module) ->
        split = Module.split(module)
        "Player" in split and module != table
      end)
    end
  end
end
