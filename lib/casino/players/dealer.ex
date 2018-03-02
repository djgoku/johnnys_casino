defmodule Casino.Player.Dealer do
  use GenServer
  require Logger

  # Client

  def start_link([table_pid]) do
    GenServer.start_link(__MODULE__, [table_pid], [name: __MODULE__])
  end

  def init([table_pid]) do
    Phoenix.PubSub.subscribe(Casino.PubSub, "table:events")

    {:ok, %{table_pid: table_pid, history: [], current_hand: []}}
  end
  
  def handle_call(:current_hand, _from, state) do
    current_hand = state[:current_hand]

    {:reply, current_hand, state}
  end

  def handle_call(:hit_or_stay, _from, state) do
    current_hand = state[:current_hand]

    sum_hand = Casino.sum_hand(current_hand)

    hit_or_stay = case sum_hand do
      [hand, _] when hand <= 17 ->
        :hit
      [_, hand] when hand <= 17 ->
        :hit
      [hand] when hand <= 17 ->
        :hit
      _ ->
        :stay
    end

    {:reply, hit_or_stay, state}
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

  def handle_info({:card_history, card}, state) do
    history = state[:history]
    new_history = history ++ [card]

    state = %{state | history: new_history}

    {:noreply, state}
  end

  def handle_info(:deck_shuffled, state) do
    {:noreply, %{state | history: []}}
  end

  def handle_info(:new_game, state) do
    
    state = %{state | current_hand: []}
    {:noreply, state}
  end
end
