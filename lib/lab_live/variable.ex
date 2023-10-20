defmodule LabLive.Variable do
  use Agent

  def start_link({name, initial_value}) do
    Agent.start_link(fn -> initial_value end, name: name)
  end

  def get(name) do
    Agent.get(name, & &1)
  end

  def set(name, val) do
    Agent.update(name, fn _ -> val end)
  end
end
