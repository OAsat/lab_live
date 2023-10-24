defmodule LabLive.Settable do
  @moduledoc """
  Settable.

  `setter/1`
      iex> {:ok, pid} = GenServer.start_link(LabLive.Settable, fn v -> v > 0 end)
      iex> LabLive.Settable.latest(pid)
      nil
      iex> LabLive.Settable.set(pid, 1)
      true
      iex> LabLive.Settable.latest(pid)
      1
      iex> LabLive.Settable.set(pid, -1)
      false
      iex> LabLive.Settable.latest(pid)
      -1

  `setter/2`
      iex> {:ok, pid} = GenServer.start_link(LabLive.Settable, fn v, nil -> v; v, old -> v > old end)
      iex> LabLive.Settable.set(pid, 1)
      1
      iex> LabLive.Settable.set(pid, 2)
      true
      iex> LabLive.Settable.set(pid, 1)
      false
  """
  use GenServer

  @spec start_link({GenServer.name(), function()}) :: GenServer.on_start()
  def start_link({name, setter}) do
    GenServer.start_link(__MODULE__, setter, name: name)
  end

  @impl GenServer
  def init(setter) when is_function(setter, 1) or is_function(setter, 2) do
    {:ok, {setter, nil}}
  end

  @impl GenServer
  def handle_call({:set, new}, _from, {setter, _}) when is_function(setter, 1) do
    value = setter.(new)
    {:reply, value, {setter, new}}
  end

  @impl GenServer
  def handle_call({:set, new}, _from, {setter, last}) when is_function(setter, 2) do
    value = setter.(new, last)
    {:reply, value, {setter, new}}
  end

  @impl GenServer
  def handle_call(:latest, _from, {setter, value}) do
    {:reply, value, {setter, value}}
  end

  @spec set(GenServer.server(), any()) :: any()
  def set(server, value) do
    GenServer.call(server, {:set, value})
  end

  @spec latest(GenServer.server()) :: any()
  def latest(server) do
    GenServer.call(server, :latest)
  end
end
