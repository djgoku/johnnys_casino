defmodule Casino.Mixfile do
  use Mix.Project

  def project do
    [
      app: :casino,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Casino.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      {:ex_card_deck, git: "https://github.com/djgoku/ex_card_deck.git"},
      {:phoenix_pubsub, "~> 1.0"}
    ]
  end
end
