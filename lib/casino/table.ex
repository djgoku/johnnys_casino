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
        {pid, []}
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
    players = state[:players]

    new_players =
      players
      |> Enum.map(fn({player, hand}) -> deal_to_player(player, hand) end)
      |> Enum.map(fn({player, hand}) -> deal_to_player(player, hand) end)

    Logger.debug("#{__MODULE__} new_players is #{inspect new_players}")

    send self(), :ask_players_hit_or_stay

    state = %{state | players: new_players}

    {:noreply, state}
  end

  def handle_info(:ask_players_hit_or_stay, state) do
    players = state[:players]

    players = Enum.map(players, fn({player, hand}) ->
      registered_name = Keyword.get(Process.info(player), :registered_name)
      hit_or_stay = registered_name.hit_or_stay()
      Logger.info("#{__MODULE__} asking player if they want to hit or stay player chose to: #{hit_or_stay}")

      card = if hit_or_stay == :hit do
        card = get_card()
        send player, {:card, card}
        [card]
      else
        []
      end

      {player, hand ++ card}
    end)

    send self(), :who_won
    state = %{state | players: players}

    {:noreply, state}
  end

  def handle_info(:who_won, state) do
    Logger.info("#{__MODULE__} seeing who want this game!")
    players = state[:players]
    {dealer, players} = List.pop_at(players, -1)
    {_, dealer_temp_hand} = dealer
    sum_hand = Casino.sum_hand(dealer_temp_hand)
    dealer_sum_hand = List.first(sum_hand)

    for p <- players do
      {pid, hand} = p
      sum_hand = Casino.sum_hand(hand)
      hand = List.first(sum_hand)
      registered_name = Keyword.get(Process.info(pid), :registered_name)
      
      case who_won(dealer_sum_hand, hand) do
        :dealer_bust ->
          Logger.info("#{__MODULE__} player #{registered_name} won because dealer bust!")
        :player_win ->
          Logger.info("#{__MODULE__} player #{registered_name} won!")
        :player_bust ->
          Logger.info("#{__MODULE__} player #{registered_name} bust!")
        :push ->
          Logger.info("#{__MODULE__} player #{registered_name} push!")
        _ ->
          Logger.info("#{__MODULE__} player #{registered_name} lost!")
      end
    end

    {:noreply, state}
  end

  def who_won(dealer_hand, _player_hand) when dealer_hand > 21, do: :dealer_bust
  def who_won(_dealer_hand, player_hand) when player_hand > 21, do: :player_bust
  def who_won(dealer_hand, player_hand) when player_hand <= 21 and player_hand > dealer_hand, do: :player_win
  def who_won(dealer_hand, player_hand) when player_hand == dealer_hand, do: :push
  def who_won(_dealer_hand, _player_hand), do: :dealer_win

  defp deal_to_player(player, hand) do
    card = get_card()
    hand = hand ++ [card]
    send player, {:card, card}
    {player, hand}
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
