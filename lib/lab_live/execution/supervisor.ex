defmodule LabLive.Execution.Supervisor do
  use Supervisor

  @impl Supervisor
  def init(nil) do
    children = [
      LabLive.Execution.Stash,
      LabLive.Execution
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 50)
  end

  def start_link(_init_arg) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end
end
