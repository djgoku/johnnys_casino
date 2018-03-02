defmodule Casino.Player.BDS do
  use GenServer
  require Logger

  # Client

  def start_link([table_pid]) do
    GenServer.start_link(__MODULE__, [table_pid], name: __MODULE__)
  end

  def init([table_pid]) do
    Phoenix.PubSub.subscribe(Casino.PubSub, "table:events")

    {:ok, %{table_pid: table_pid, history: [], current_hand: []}}
  end

  def handle_call(:hit_or_stay, _from, state) do
    current_hand = state[:current_hand]
    history = state[:history]

    sum_hand = Casino.sum_hand(current_hand)

    hit_or_stay =
      case sum_hand do
        [hand, _] when hand <= 16 ->
          if _count_cards(history) > 0, do: :hit, else: :stay

        [_, hand] when hand <= 16 ->
          if _count_cards(history) > 0, do: :hit, else: :stay

        [hand] when hand <= 16 ->
          if _count_cards(history) > 0, do: :hit, else: :stay

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

  def _count_cards(history) do
    Enum.reduce(history, 0, fn card, count ->
      case card do
        {_, "2", _, _} -> count + 1
        {_, "3", _, _} -> count + 1
        {_, "4", _, _} -> count + 1
        {_, "5", _, _} -> count + 1
        {_, "6", _, _} -> count + 1
        {_, "7", _, _} -> count
        {_, "8", _, _} -> count
        {_, "9", _, _} -> count
        {_, "10", _, _} -> count - 1
        {_, "J", _, _} -> count - 1
        {_, "Q", _, _} -> count - 1
        {_, "K", _, _} -> count - 1
        {_, "A", _, _} -> count - 1
      end
    end)
  end
end
