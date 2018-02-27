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

  def get_players() do
    GenServer.call(__MODULE__, :get_players)
  end

  # Server

  def handle_call(:get_players, _from, state) do
    {:reply, state[:players], state}
  end

  def handle_info(:after_init, state) do
    players = Casino.Table.find_players() ++ [Casino.Player.Dealer]

    pids = if length(players) <= state[:max_players] do
      Logger.info("(Casino.Table) starting a game with #{length(players)} of players")
      Enum.map(players, fn(player) ->
        {:ok, pid} = player.start_link([self()])
        pid
      end)
    else
      Logger.error("(Casino.Table) unable to start game since max players met: #{inspect(players)}")
      []
    end

    send self(), :start_game
    state = %{state | players: pids}

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    Logger.info("(Casino.Table) starting a black jack game.")
    players = state[:players] ++ state[:players]

    Enum.map(players, fn(player) ->
      card = get_card()
      send player, {:card, card}
    end)

    send self(), :ask_players_hit_or_stay

    {:noreply, state}
  end

  def handle_info(:ask_players_hit_or_stay, state) do
    players = state[:players]

    Enum.map(players, fn(player) ->
      registered_name = Keyword.get(Process.info(player), :registered_name)
      hit_or_stay = registered_name.hit_or_stay()
      Logger.info("#{__MODULE__} asking player if they want to hit or stay player chose to: #{hit_or_stay}")

      if hit_or_stay == :hit do
        card = get_card()
        send player, card
      end
    end)

    # send self(), :who_won

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

  def find_players() do
    table = Casino.Player.Dealer

    with {:ok, list} <- :application.get_key(:casino, :modules) do
      list
      |> Enum.filter(fn(module) ->
        split = Module.split(module)
        "Player" in split and module != table
      end)
    end
  end
end
