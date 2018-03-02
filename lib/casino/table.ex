defmodule Casino.Table do
  @moduledoc """
  A table controls all aspects of a table at johnny's casino.
  """

  use GenServer
  require Logger

  # Client

  @doc """
  TODO
   - 
  """

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    send(self(), :after_init)

    :ets.new(:player_stats, [:set, :protected, :named_table])

    {:ok,
     %{
       players: [],
       max_players: 7,
       total_games: 0,
       total_rounds: 0,
       number_of_rounds: 2,
       number_of_games: 100,
       player_stats: []
     }}
  end

  def terminate(_reason, state) do
    # Logger.debug("#{__MODULE__} terminating")
    players = state[:players]

    Enum.map(players, fn {pid, _hand} ->
      GenServer.stop(pid)
    end)

    :stop
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

    pids =
      if length(players) <= state[:max_players] do
        # Logger.info("(Casino.Table) starting a game with #{length(players)} of players")

        Enum.map(players, fn player ->
          {:ok, pid} = player.start_link([self()])
          {pid, []}
        end)
      else
        # Logger.error(
        # "(Casino.Table) unable to start game since max players met: #{inspect(players)}"
        # )

        []
      end

    player_stats =
      Enum.map(pids, fn {pid, _} ->
        registered_name = Keyword.get(Process.info(pid), :registered_name)
        # {pid, bust, loss, push, win}
        {registered_name, {0, 0, 0, 0}}
      end)

    send(self(), :start_game)
    state = %{state | players: pids, player_stats: player_stats}

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    # Logger.info("(Casino.Table) starting a black jack game.")
    players = state[:players]

    new_players =
      players
      |> Enum.map(fn {player, hand} -> deal_to_player(player, hand) end)
      |> Enum.map(fn {player, hand} -> deal_to_player(player, hand) end)

    send(self(), :ask_players_hit_or_stay)

    state = %{state | players: new_players}

    {:noreply, state}
  end

  def handle_info(:ask_players_hit_or_stay, state) do
    players = state[:players]

    players =
      Enum.map(players, fn {player, hand} ->
        answer = GenServer.call(player, :hit_or_stay)
        cards = hit_or_stay(answer, hand, player)

        {player, cards}
      end)

    send(self(), :who_won)
    state = %{state | players: players}

    {:noreply, state}
  end

  def handle_info(:next_round, state) do
    number_of_rounds = state[:number_of_rounds]
    total_rounds = state[:total_rounds]

    total_rounds = total_rounds + 1

    state =
      if total_rounds < number_of_rounds do
        Phoenix.PubSub.broadcast(Casino.PubSub, "table:events", :new_game)

        players =
          Enum.map(state[:players], fn {pid, _} ->
            {pid, []}
          end)

        player_stats =
          Enum.map(state[:players], fn {pid, _} ->
            registered_name = Keyword.get(Process.info(pid), :registered_name)
            {registered_name, {0, 0, 0, 0}}
          end)

        send(self(), :start_game)

        %{
          state
          | players: players,
            player_stats: player_stats,
            total_games: 0,
            total_rounds: total_rounds
        }
      else
        print_all_game_stats(state[:players])
        Logger.info("#{__MODULE__} we are at the end of the gambling road")
        %{state | total_rounds: total_rounds}
      end

    {:noreply, state}
  end

  def handle_info(:next_game, state) do
    number_of_games = state[:number_of_games]
    total_games = state[:total_games]
    players = state[:players]

    total_games = total_games + 1

    players =
      if total_games < number_of_games do
        send(self(), :start_game)

        Enum.map(players, fn p ->
          {pid, _} = p
          send(pid, :new_game)
          {pid, []}
        end)
      else
        # Logger.info("#{__MODULE__} well that's the game folks!")
        player_stats = state[:player_stats]
        print_game_stats(player_stats)
        send(self(), :next_round)
        players
      end

    state = %{state | players: players, total_games: total_games}

    {:noreply, state}
  end

  def handle_info(:who_won, state) do
    # Logger.info("#{__MODULE__} seeing who want this game!")
    players = state[:players]
    {dealer, players} = List.pop_at(players, -1)
    {dealer_pid, dealer_temp_hand} = dealer
    dealer_registered_name = Keyword.get(Process.info(dealer_pid), :registered_name)
    sum_hand = Casino.sum_hand(dealer_temp_hand)

    dealer_sum_hand =
      case sum_hand do
        [hand1, hand2] when hand1 > 21 ->
          hand2

        [hand1, _] ->
          hand1

        [hand] ->
          hand
      end

    for p <- players do
      {pid, hand} = p
      sum_hand = Casino.sum_hand(hand)
      hand = List.first(sum_hand)
      registered_name = Keyword.get(Process.info(pid), :registered_name)

      case who_won(dealer_sum_hand, hand) do
        :dealer_bust ->
          send(self(), {:player_stats, registered_name, :win})
          send(self(), {:player_stats, dealer_registered_name, :bust})

        # Logger.info(
        #   "#{__MODULE__} player #{registered_name} had #{hand} and won, dealer bust with #{
        #     dealer_sum_hand
        #   }!"
        # )

        :player_win ->
          send(self(), {:player_stats, registered_name, :win})
          send(self(), {:player_stats, dealer_registered_name, :loss})

        # Logger.info(
        #   "#{__MODULE__} player #{registered_name} had #{hand} and won, dealer lost with #{
        #     dealer_sum_hand
        #   }!"
        # )

        :player_bust ->
          send(self(), {:player_stats, registered_name, :bust})
          send(self(), {:player_stats, dealer_registered_name, :win})

        # Logger.info(
        #   "#{__MODULE__} player #{registered_name} had #{hand} and bust, dealer won with #{
        #     dealer_sum_hand
        #   }!"
        # )

        :push ->
          send(self(), {:player_stats, registered_name, :push})
          send(self(), {:player_stats, dealer_registered_name, :push})

        # Logger.info(
        #   "#{__MODULE__} player #{registered_name} had #{hand} and pushed, dealer pushed with #{
        #     dealer_sum_hand
        #   }!!"
        # )

        _ ->
          send(self(), {:player_stats, registered_name, :loss})
          send(self(), {:player_stats, dealer_registered_name, :win})

          # Logger.info(
          #   "#{__MODULE__} player #{registered_name} had #{hand} and lost, dealer won with #{
          #     dealer_sum_hand
          #   }!!"
          # )
      end
    end

    send(self(), :next_game)

    {:noreply, state}
  end

  def handle_info({:player_stats, pid, outcome}, state) do
    player_stats = state[:player_stats]

    {_, new_player_stats} =
      Keyword.get_and_update(player_stats, pid, fn stats ->
        {b, l, p, w} = stats

        new_stats =
          case outcome do
            :bust ->
              {b + 1, l, p, w}

            :loss ->
              {b, l + 1, p, w}

            :push ->
              {b, l, p + 1, w}

            :win ->
              {b, l, p, w + 1}
          end

        {stats, new_stats}
      end)

    state = %{state | player_stats: new_player_stats}

    {:noreply, state}
  end

  def print_game_stats(player_stats) do
    Enum.map(player_stats, fn {player, {busts, losses, pushes, wins}} ->
      # "#{player}: busts #{busts}, losses #{losses}, pushes #{pushes}, wins #{wins}\n"
      stats = :ets.lookup(:player_stats, Elixir.Casino.Player.Dealer)

      if stats == [] do
        :ets.insert(:player_stats, {player, [{busts, losses, pushes, wins}]})
      else
        [{_, all_stats}] = stats
        new_all_stats = all_stats ++ [{busts, losses, pushes, wins}]
        :ets.insert(:player_stats, {player, new_all_stats})
      end
    end)
  end

  def print_all_game_stats(players) do
    Enum.map(players, fn {pid, _} ->
      registered_name = Keyword.get(Process.info(pid), :registered_name)
      [{_, all_stats}] = :ets.lookup(:player_stats, Elixir.Casino.Player.Dealer)

      new_all_stats =
        Enum.map(all_stats, fn {b, l, p, w} ->
          "#{registered_name},#{b},#{l},#{p},#{w}\n"
        end)

      File.write("./results.txt", new_all_stats, [:append])
    end)
  end

  def hit_or_stay(:stay, cards, _server), do: cards
  def hit_or_stay(:bust, cards, _server), do: cards

  def hit_or_stay(:hit, cards, server) do
    card = get_card()
    send(server, {:card, card})
    cards = cards ++ [card]

    sum_hand = Casino.sum_hand(cards)

    case sum_hand do
      [_, hand2] when hand2 > 21 ->
        hit_or_stay(:bust, cards, server)

      [hand] when hand > 21 ->
        hit_or_stay(:bust, cards, server)

      _ ->
        answer = GenServer.call(server, :hit_or_stay)
        hit_or_stay(answer, cards, server)
    end
  end

  def hit_or_stay(_, _cards, server), do: []

  def who_won(dealer_hand, _player_hand) when dealer_hand > 21, do: :dealer_bust
  def who_won(_dealer_hand, player_hand) when player_hand > 21, do: :player_bust

  def who_won(dealer_hand, player_hand) when player_hand <= 21 and player_hand > dealer_hand,
    do: :player_win

  def who_won(dealer_hand, player_hand) when player_hand == dealer_hand, do: :push
  def who_won(_dealer_hand, _player_hand), do: :dealer_win

  defp deal_to_player(player, hand) do
    card = get_card()
    hand = hand ++ [card]
    send(player, {:card, card})
    {player, hand}
  end

  defp get_card() do
    case ExCardDeck.get_card() do
      nil ->
        Phoenix.PubSub.broadcast(Casino.PubSub, "table:events", :deck_shuffled)
        ExCardDeck.shuffle()
        card = ExCardDeck.get_card()
        Phoenix.PubSub.broadcast(Casino.PubSub, "table:events", {:card_history, card})
        card

      card ->
        Phoenix.PubSub.broadcast(Casino.PubSub, "table:events", {:card_history, card})
        card
    end
  end

  def find_players() do
    table = Casino.Player.Dealer

    with {:ok, list} <- :application.get_key(:casino, :modules) do
      list
      |> Enum.filter(fn module ->
        split = Module.split(module)
        "Player" in split and module != table
      end)
    end
  end
end
