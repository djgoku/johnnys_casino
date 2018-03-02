defmodule Casino.Player.GregAndJordan do
  use GenServer
  require Logger

  # Client

  def start_link([table_pid]) do
    GenServer.start_link(__MODULE__, [table_pid], name: __MODULE__)
  end

  def init([table_pid]) do
    Phoenix.PubSub.subscribe(Casino.PubSub, "table:events")

    {:ok, %{table_pid: table_pid, history: [], current_hand: [], remaining_deck: get_deck()}}
  end

  def handle_call(:current_hand, _from, state) do
    current_hand = state[:current_hand]

    {:reply, current_hand, state}
  end

  def handle_call(:hit_or_stay, _from, state) do
    current_hand = state[:current_hand]

    dealer_hand = GenServer.call(Casino.Player.Dealer, :current_hand)

    sum_dealer = Casino.sum_hand(dealer_hand)
    sum_hand = Casino.sum_hand(current_hand)

    deck_average = average_deck(state[:remaining_deck])
    # add_deck_to_hand = can_add_deck_to_hand(current_hand, state[:remaining_deck])
    add_deck_to_hand = false
    Logger.info("#{__MODULE__} deck average = #{inspect(deck_average)}")

    hit_or_stay =
      case {sum_hand, sum_dealer} do
        {_, [dealer]} when dealer > 21 ->
          :stay

        {_, [dealer_a, dealer_b]} when dealer_a > 21 and dealer_b > 21 ->
          :stay

        {[us], [dealer]} when us < dealer ->
          :hit

        {[us], [dealer]} ->
          greater_than_dealer_single(us, dealer, deck_average, add_deck_to_hand)

        {[us_a, us_b], [dealer]} when us_a < dealer and us_b < dealer ->
          :hit

        {[us_a, us_b], [dealer]} ->
          greater_than_dealer_single(us_a, dealer, deck_average, add_deck_to_hand)

        {[us], [dealer_a, dealer_b]} when us < dealer_a or us < dealer_b ->
          :hit

        {[us], [dealer_a, dealer_b]} ->
          greater_than_dealer_single(us, dealer_a, deck_average, add_deck_to_hand)

        {our_pairs, dealer_pairs} ->
          if Enum.max(our_pairs) < Enum.max(dealer_pairs) do
            :hit
          else
            :stay
          end
      end

    {:reply, hit_or_stay, state}
  end

  defp greater_than_dealer_single(us, dealer, deck_average, can_add_deck) do
    if us + deck_average <= 21 do
      :hit
    else
      :stay
    end
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
    remaining_deck = state[:remaining_deck]
    new_history = history ++ [card]

    new_deck = Enum.reject(remaining_deck, &(&1 == card))

    state = %{state | history: new_history, remaining_deck: new_deck}

    {:noreply, state}
  end

  def handle_info(:deck_shuffled, state) do
    {:noreply, %{state | history: [], remaining_deck: get_deck()}}
  end

  defp average_deck(deck) do
    total =
      Enum.reduce(deck, 0, fn
        {_, _, _, [val]}, acc -> acc + val
        {_, _, _, [_, _]}, acc -> acc + 6
      end)

    num_cards = length(deck)

    if num_cards == 0 do
      0
    else
      total / num_cards
    end
  end

  def handle_info(:new_game, state) do
    state = %{state | current_hand: []}
    {:noreply, state}
  end

  defp get_deck() do
    ExCardDeck.deck() |> List.flatten()
  end

  defp can_add_deck_to_hand(current_hand, deck) do
    results =
      Enum.map(deck, fn card ->
        new_hand = [card | current_hand]
        hand_sum = Casino.sum_hand(new_hand)

        case hand_sum do
          [s] when s > 21 ->
            :bust

          [s] ->
            :in

          [s, t] when s > 21 and t > 21 ->
            :bust

          _ ->
            :in
        end
      end)

    num_success = results |> Enum.filter(fn r -> r == :in end) |> length
    num_failures = length(results) - num_success

    num_success > num_failures
  end
end
