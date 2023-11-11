defmodule LabLive.Execution.Stash do
@moduledoc false
  use Agent

  def start_link(_init_arg) do
    Agent.start_link(fn -> %LabLive.Execution.Worker.State{} end, name: __MODULE__)
  end

  def update(value) do
    Agent.update(__MODULE__, fn _ -> value end)
  end

  def get() do
    Agent.get(__MODULE__, & &1)
  end
end
