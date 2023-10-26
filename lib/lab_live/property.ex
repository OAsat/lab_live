defmodule LabLive.Property do
  @moduledoc """
  Server to hold a value.

      iex> {:ok, pid} = LabLive.Property.start_link(:a)
      iex> LabLive.Property.get(pid)
      :init
      iex> LabLive.Property.update(pid, 1)
      iex> LabLive.Property.get(pid)
      1
  """
  use Agent

  def start_link(name) do
    Agent.start_link(fn -> :init end, name: name)
  end

  def get(name) do
    Agent.get(name, & &1)
  end

  def update(name, val) do
    Agent.update(name, fn _ -> val end)
  end
end
