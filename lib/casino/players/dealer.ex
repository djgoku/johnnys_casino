defmodule Casino.Player.Dealer do
  use GenServer
  require Logger

  # Client

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    player_number = case Casino.Table.join() do
      {:player, player_number} ->
        player_number
      {:error, :max_players_at_table} ->
        0
    end

    if is_integer(player_number) and player_number > 0 do
      {:ok, %{player_number: player_number, history: [], current_hand: []}}
    else
      Logger.debug("#{__MODULE__} stop initializing since max_players_at_table.")
      {:stop, :max_players_at_table}
    end
  end

  def dealt_card(card) do
    GenServer.cast(__MODULE__, {:dealt_card, card})
  end

  def deck_shuffled() do
    GenServer.cast(__MODULE__, :deck_shuffled)
  end

  def hit_or_stay() do
    GenServer.call(__MODULE__, :hit_or_stay)
  end

  def handle_info(:hit_or_stay, _from, state) do
    {:reply, :stay, state}
  end

  def handle_info({:card, card}, state) do
    Logger.info("(#{__MODULE__}) we were dealt a #{inspect(card)}")
    current_hand = state[:current_hand]
    history = state[:history]

    new_current_hand = current_hand ++ [card]
    new_history = history ++ [card]

    state = %{state | current_hand: new_current_hand, history: new_history}

    {:noreply, state}
  end

  def handle_info(:deck_shuffled, state) do
    {:noreply, %{state | history: [], current_hand: []}}
  end
end