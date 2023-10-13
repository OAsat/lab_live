defmodule Labex.Application do
  @moduledoc false

  use Application
  alias Labex.StoreManager
  alias Labex.InstrumentManager

  @impl true
  def start(_type, _args) do
    children = [
      InstrumentManager,
      StoreManager
    ]

    opts = [strategy: :one_for_all, name: Labex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
