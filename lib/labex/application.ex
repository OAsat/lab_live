defmodule Labex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # {DynamicSupervisor, name: Labex.Instrument.Supervisor, strategy: :one_for_one},
      # {Registry, keys: :unique, name: Labex.Instrument.Registry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: Labex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
