defmodule LabLive.Application do
  @moduledoc false

  use Application
  alias LabLive.StoreManager
  alias LabLive.InstrumentManager

  @impl true
  def start(_type, _args) do
    children = [
      InstrumentManager,
      StoreManager
    ]

    opts = [strategy: :one_for_all, name: LabLive.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
