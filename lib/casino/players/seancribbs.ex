defmodule Casino.Player.SeanCribbs do
  use GenServer
  require Logger

  # Client
  @ranks [
    {"A", 0, [1, 11]},
    {"2", 1, [2]},
    {"3", 2, [3]},
    {"4", 3, [4]},
    {"5", 4, [5]},
    {"6", 5, [6]},
    {"7", 6, [7]},
    {"8", 7, [8]},
    {"9", 8, [9]},
    {"10", 9, [10]},
    {"J", 10, [10]},
    {"Q", 11, [10]},
    {"K", 12, [10]}
  ]

  def start_link([table_pid]) do
    GenServer.start_link(__MODULE__, [table_pid], name: __MODULE__)
  end

  def init([table_pid]) do
    Phoenix.PubSub.subscribe(Casino.PubSub, "table:events")

    {:ok, %{table_pid: table_pid, history: new_history(), current_hand: []}}
  end

  def hit_or_stay() do
    GenServer.call(__MODULE__, :hit_or_stay)
  end

  def handle_call(:hit_or_stay, _from, state = %{current_hand: current_hand, history: history}) do
    action =
      case hit_prob(current_hand, history) do
        n when n >= 0 ->
          # Logger.info("(#{__MODULE__}) Probability of good hit: #{n}")
          :hit

        _ ->
          :stay
      end

    {:reply, action, state}
  end

  def handle_info({:card, card}, state = %{current_hand: current_hand}) do
    # Logger.info("(#{__MODULE__}) we were dealt a #{inspect(card)}")

    state = %{state | current_hand: [card | current_hand]}

    {:noreply, state}
  end

  def handle_info({:card_history, {_suit, rank, _symbol, scores}}, state = %{history: history}) do
    state = %{state | history: Map.update!(history, {rank, scores}, &increment_rank/1)}

    {:noreply, state}
  end

  def handle_info(:deck_shuffled, state) do
    {:noreply, %{state | history: new_history()}}
  end

  def handle_info(:new_game, state) do
    state = %{state | current_hand: []}
    {:noreply, state}
  end

  defp hit_prob(hand, history) do
    # Get only available cards
    # Fill out the remaining cards literally
    # Get all the possible outcomes
    # Rank each game based on a subjective scoring
    history
    |> Enum.filter(fn {_card, count} -> count < 4 end)
    |> Enum.flat_map(fn {card, count} ->
      List.duplicate(card, 4 - count)
    end)
    |> Enum.flat_map(fn {rank, scores} ->
      fake_card = {:fake, rank, 0, scores}
      Casino.sum_hand([fake_card | hand])
    end)
    |> Enum.map(fn score ->
      cond do
        score == 21 -> 2
        score > 21 -> -2
        true -> 1
      end
    end)
    |> Enum.sum()
  end

  defp new_history() do
    for {rank, _, scores} <- @ranks, into: %{} do
      {{rank, scores}, 0}
    end
  end

  defp increment_rank(nil), do: 1
  defp increment_rank(n), do: n + 1
end
