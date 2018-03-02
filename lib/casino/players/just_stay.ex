defmodule Casino.Player.JustStay do
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

  def hit_or_stay() do
    GenServer.call(__MODULE__, :hit_or_stay)
  end

  def handle_call(:hit_or_stay, _from, state) do
    {:reply, :stay, state}
  end

  def handle_info({:card, card}, state) do
    Logger.info("(#{__MODULE__}) we were dealt a #{inspect(card)}")
    current_hand = state[:current_hand]

    new_current_hand = current_hand ++ [card]

    state = %{state | current_hand: new_current_hand}

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
