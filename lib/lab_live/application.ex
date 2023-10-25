defmodule LabLive.Application do
  @moduledoc false

  use Application
  alias LabLive.Variables
  alias LabLive.Instrument

  @impl true
  def start(_type, _args) do
    children = [
      Instrument,
      Variables
    ]

    opts = [strategy: :one_for_one, name: LabLive.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
