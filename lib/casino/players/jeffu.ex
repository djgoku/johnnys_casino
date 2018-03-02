defmodule Casino.Player.JeffU do
  use GenServer
  require Logger

  @high_threshold 16
  @dealer_sum_threshold 17
  @high_card_threshold 10
  @high_card_value 8

  # Client

  def start_link([table_pid]) do
    GenServer.start_link(__MODULE__, [table_pid], [name: __MODULE__])
  end

  def init([table_pid]) do
    Phoenix.PubSub.subscribe(Casino.PubSub, "table:events")

    {:ok, %{table_pid: table_pid, history: [], current_hand: []}}
  end

  def handle_call(:hit_or_stay, _from, state) do
    current_hand = state[:current_hand]

    dealer_hand =
      Casino.Player.Dealer
      |> GenServer.call(:current_hand)

    sum_dealer =
      dealer_hand
      |> Casino.sum_hand()
      |> Enum.min()

    sum_hand =
      current_hand
      |> Casino.sum_hand()
      |> Enum.min()

    high_card_count =
      state.history
      |> high_card_count(@high_card_value)

    hit_or_stay =
      case {sum_hand, high_card_count} do
        {hand, high_card_count} when hand <= @high_threshold and high_card_count > @high_card_threshold -> dealer_hit(sum_dealer)
        _ ->
          :stay
      end

    {:reply, hit_or_stay, state}
  end

  defp dealer_hit(sum_dealer) do
    case sum_dealer do
      value when value <= @dealer_sum_threshold -> :hit
      _ -> :stay
    end
  end

  defp high_card_count(card_list, high_card) do
    Enum.filter(card_list, fn
      {_suit, _face, _int, [_, value]} -> value > high_card
      {_suit, _face, _int, [value]} -> value > high_card
    end)
    |> length
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
