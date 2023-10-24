defmodule LabLive.Getter do
  @moduledoc """
  Server to hold function and state.
  The state can only be updated by calling the getter function.

  `getter/0`
      iex> {:ok, pid} = GenServer.start_link(LabLive.Getter, fn -> 1 end)
      iex> LabLive.Getter.latest(pid)
      nil
      iex> LabLive.Getter.get(pid)
      1
      iex> LabLive.Getter.latest(pid)
      1

  `getter/1`
      iex> {:ok, pid} = GenServer.start_link(LabLive.Getter, fn nil -> 1; value -> value + 1 end)
      iex> LabLive.Getter.get(pid)
      1
      iex> LabLive.Getter.get(pid)
      2
  """
  use GenServer

  @spec start_link({GenServer.name(), function()}) :: GenServer.on_start()
  def start_link({name, getter}) do
    GenServer.start_link(__MODULE__, getter, name: name)
  end

  @impl GenServer
  def init(getter) when is_function(getter, 0) or is_function(getter, 1) do
    {:ok, {getter, nil}}
  end

  @impl GenServer
  def handle_call(:get, _from, {getter, _}) when is_function(getter, 0) do
    value = getter.()
    {:reply, value, {getter, value}}
  end

  @impl GenServer
  def handle_call(:get, _from, {getter, latest}) when is_function(getter, 1) do
    value = getter.(latest)
    {:reply, value, {getter, value}}
  end

  @impl GenServer
  def handle_call(:latest, _from, {getter, value}) do
    {:reply, value, {getter, value}}
  end

  @spec get(GenServer.server()) :: any()
  def get(server) do
    GenServer.call(server, :get)
  end

  @spec latest(GenServer.server()) :: any()
  def latest(server) do
    GenServer.call(server, :latest)
  end
end
