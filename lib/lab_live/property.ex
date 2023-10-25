defmodule LabLive.Property do
  @moduledoc """
  A variable is a server that holds a value and a function to update the value.

  with `update_function/0`
      iex> {:ok, agent} = Agent.start_link(fn -> 0 end)
      iex> update_function = fn -> Agent.update(agent, &(&1 + 1)); Agent.get(agent, & &1) end
      iex> {:ok, pid} = GenServer.start_link(LabLive.Property, update_function)
      iex> LabLive.Property.latest(pid)
      nil
      iex> LabLive.Property.update(pid)
      1
      iex> LabLive.Property.latest(pid)
      1
      iex> LabLive.Property.update(pid)
      2

  with `update_function/1`
      iex> {:ok, pid} = GenServer.start_link(LabLive.Property, fn v -> v > 0 end)
      iex> LabLive.Property.latest(pid)
      nil
      iex> LabLive.Property.update(pid, 1)
      true
      iex> LabLive.Property.latest(pid)
      true
      iex> LabLive.Property.update(pid, -1)
      false
      iex> LabLive.Property.latest(pid)
      false
  """

  use GenServer

  @spec start_link({GenServer.name(), function()}) :: GenServer.on_start()
  def start_link({name, function}) do
    GenServer.start_link(__MODULE__, function, name: name)
  end

  @impl GenServer
  def init(function) when is_function(function, 0) do
    {:ok, {function, nil}}
  end

  @impl GenServer
  def init(function) when is_function(function, 1) do
    {:ok, {function, nil}}
  end

  @impl GenServer
  def handle_call({:update, nil}, _from, {function, _}) when is_function(function, 0) do
    value = function.()
    {:reply, value, {function, value}}
  end

  @impl GenServer
  def handle_call({:update, args}, _from, {function, _}) when is_function(function, 1) do
    value = function.(args)
    {:reply, value, {function, value}}
  end

  @impl GenServer
  def handle_call(:latest, _from, state = {_, value}) do
    {:reply, value, state}
  end

  @doc """
  Executes the function to update the state and returns the value.
  """
  @spec update(GenServer.server(), any()) :: any()
  def update(server, args \\ nil) do
    GenServer.call(server, {:update, args})
  end

  @doc """
  Returns the result of the latest update.
  """
  @spec latest(GenServer.server()) :: any()
  def latest(server) do
    GenServer.call(server, :latest)
  end
end
