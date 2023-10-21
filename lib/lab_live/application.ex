defmodule LabLive.Application do
  @moduledoc false

  use Application
  alias LabLive.VariableManager
  alias LabLive.InstrumentManager

  @impl true
  def start(_type, _args) do
    children = [
      InstrumentManager,
      VariableManager
    ]

    opts = [strategy: :one_for_one, name: LabLive.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
