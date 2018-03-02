defmodule Casino.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    import Supervisor.Spec, warn: false

    children = [
      # {Casino.Table, []},
      {ExCardDeck, 1},
      supervisor(Phoenix.PubSub.PG2, [Casino.PubSub, []])
      # Starts a worker by calling: Casino.Worker.start_link(arg)
      # {Casino.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Casino.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
