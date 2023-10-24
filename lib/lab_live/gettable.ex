defmodule LabLive.Gettable do
  @moduledoc """
  Store with getter function.

  `getter/0`
      iex> {:ok, pid} = GenServer.start_link(LabLive.Gettable, fn -> 1 end)
      iex> LabLive.Gettable.latest(pid)
      nil
      iex> LabLive.Gettable.get(pid)
      1
      iex> LabLive.Gettable.latest(pid)
      1

  `getter/1`
      iex> {:ok, pid} = GenServer.start_link(LabLive.Gettable, fn nil -> 1; value -> value + 1 end)
      iex> LabLive.Gettable.get(pid)
      1
      iex> LabLive.Gettable.get(pid)
      2
  """
  use GenServer

  def start_link({name, getter}) do
    GenServer.start_link(__MODULE__, getter, name: name)
  end

  @impl GenServer
  def init(getter) do
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
