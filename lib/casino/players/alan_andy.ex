defmodule Casino.Player.AlanAndy do
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

  def handle_call(:hit_or_stay, _from, %{history: history, current_hand: current_hand} = state) do
    dealer_hand = GenServer.call(Casino.Player.Dealer, :current_hand)
    dealer_count = Casino.sum_hand(dealer_hand) |> List.last
    our_count = Casino.sum_hand(current_hand) |> List.first

    # if dealer between 2-6, hit until zero danger
    # if dealer between 7-11, hit until at least 17
    # if dealer between 12-16, hit until zero danger
    # if dealter is between 17-21, hit until same or more as dealer
    action =
      cond do
        dealer_count <= 6 && our_count > 11 ->
          :stay
        dealer_count <= 6 ->
          :hit
        dealer_count <= 11 && our_count < 17 ->
          :hit
        dealer_count <= 11 ->
          :stay
        dealer_count <= 16 && our_count > 11 ->
          :stay
        dealer_count <= 16 ->
          :hit
        dealer_count <= 21 && our_count < dealer_count ->
          :hit
        true ->
          :stay
      end

    {:reply, action, state}
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
