# Casino

## Card

```elixir
# {suit, string_representation, unicode_integer, values}

# This is the 3 of spades.
{:spades, "3", 127139, [3]}

# This is the A of diamonds.
{:diamonds, "A", 127169, [1, 11]}
```

## The Game

The only thing the user has to do is reply with :hit or :stay. The player does get all card info even for dealer. The dealer has to hit until 17 or more total in cards. The dealer is also programmed to hit on soft 17. The player has access to card history but after a shuffle this will be cleared. The player also has a current_hand to show its current hand to make partial decisions on.

1. Copy Casino.Player.Dealer (lib/casino/players/dealer.ex) into a new player file.
2. Have fun!

Johnny5