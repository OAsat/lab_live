defmodule LabLive.Property do
  @moduledoc """
  Server to hold a value.

      iex> {:ok, pid} = LabLive.Property.start_link(name: :a)
      iex> LabLive.Property.get(pid)
      :empty
      iex> LabLive.Property.update(pid, 1)
      iex> LabLive.Property.get(pid)
      1

      iex> {:ok, pid} = LabLive.Property.start_link(name: :b, stats: 2)
      iex> LabLive.Property.update(pid, 1)
      iex> LabLive.Property.stats(pid)
      %LabLive.Stats{max_size: 2, queue: {[1], []}, size: 1, square_sum: 1, sum: 1}
      iex> LabLive.Property.update(pid, 2)
      iex> LabLive.Property.stats(pid)
      %LabLive.Stats{max_size: 2, queue: {[2], [1]}, size: 2, square_sum: 5, sum: 3}
      iex> LabLive.Property.update(pid, 3)
      iex> LabLive.Property.stats(pid)
      %LabLive.Stats{max_size: 2, queue: {[3], [2]}, size: 2, square_sum: 13, sum: 5}
  """
  use Agent

  def start_link(opts) do
    init_stats =
      case opts[:stats] do
        nil -> nil
        true -> %LabLive.Stats{max_size: :inf}
        n -> %LabLive.Stats{max_size: n}
      end

    Agent.start_link(fn -> {:empty, init_stats} end, name: opts[:name])
  end

  @spec get(GenServer.server()) :: any()
  def get(server) do
    Agent.get(server, fn {val, _stats} -> val end)
  end

  @spec update(GenServer.server(), any()) :: :ok
  def update(server, val) do
    Agent.update(server, fn
      {_val, nil} -> {val, nil}
      {_val, stats} -> {val, LabLive.Stats.append(stats, val)}
    end)
  end

  @spec stats(GenServer.server()) :: nil | LabLive.Stats.t()
  def stats(server) do
    Agent.get(server, fn {_val, stats} -> stats end)
  end

  @spec mean(GenServer.server()) :: nil | float()
  def mean(server) do
    stats(server) |> LabLive.Stats.mean()
  end

  @spec stddev(GenServer.server()) :: nil | float()
  def stddev(server) do
    stats(server) |> LabLive.Stats.stddev()
  end
end
