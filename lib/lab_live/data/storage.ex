defmodule LabLive.Data.Storage do
  @moduledoc """
  Server to hold a value.

      iex> alias LabLive.Data.Storage
      iex> {:ok, pid} = Storage.start_link()
      iex> Storage.get(pid)
      nil
      iex> Storage.update(pid, 1)
      iex> Storage.get(pid)
      1

  Starting with a name.
      iex> alias LabLive.Data.Storage
      iex> {:ok, _pid} = Storage.start_link(name: :my_storage)
      iex> Storage.update(:my_storage, 1)
      iex> Storage.get(:my_storage)
      1

  Starting with an initial value.
      iex> alias LabLive.Data.Storage
      iex> {:ok, pid} = Storage.start_link(init: 10)
      iex> Storage.get(pid)
      10

  Statistics of cached values.
      iex> alias LabLive.Data.Storage
      iex> {:ok, pid} = Storage.start_link(stats: 3, init: 10)
      iex> Storage.stats(pid)
      %LabLive.Data.Stats{max_size: 3, queue: {[10], []}, size: 1, square_sum: 100, sum: 10}
      iex> Storage.update(pid, 1)
      iex> Storage.stats(pid)
      %LabLive.Data.Stats{max_size: 3, queue: {[1], [10]}, size: 2, square_sum: 101, sum: 11}
      iex> Storage.update(pid, 2)
      iex> Storage.stats(pid)
      %LabLive.Data.Stats{max_size: 3, queue: {[2, 1], [10]}, size: 3, square_sum: 105, sum: 13}
      iex> Storage.update(pid, 3)
      iex> Storage.stats(pid)
      %LabLive.Data.Stats{max_size: 3, queue: {[3], [1, 2]}, size: 3, square_sum: 14, sum: 6}
  """
  defstruct [:value, :stats, :opts]

  alias LabLive.Data.Stats
  use Agent

  @type t() :: %__MODULE__{
          value: any(),
          stats: nil | Stats.t(),
          opts: Keyword.t()
        }

  @type opt() :: {atom(), any()} | {:stats, Stats.max_size()} | {:init, any()}
  @type opts() :: [opt()]

  def start_link(opts \\ []) do
    Agent.start_link(fn -> init_value(opts) end, name: opts[:name])
  end

  defp init_value(opts) do
    stats =
      case {opts[:stats], opts[:init]} do
        {nil, _} -> nil
        {max_size, nil} -> Stats.new([], max_size)
        {max_size, init} -> Stats.new([init], max_size)
      end

    %__MODULE__{value: opts[:init], stats: stats, opts: opts}
  end

  @spec get(GenServer.server()) :: any()
  def get(server) do
    Agent.get(server, fn %__MODULE__{value: value} -> value end)
  end

  @spec update(GenServer.server(), any()) :: :ok
  def update(server, val) do
    Agent.update(server, fn state = %__MODULE__{stats: stats} ->
      case stats do
        nil -> %__MODULE__{state | value: val}
        _ -> %__MODULE__{state | value: val, stats: Stats.append(stats, val)}
      end
    end)
  end

  @spec stats(GenServer.server()) :: nil | Stats.t()
  def stats(server) do
    Agent.get(server, fn %__MODULE__{stats: stats} -> stats end)
  end

  @spec get_state(GenServer.server()) :: t()
  def get_state(server) do
    Agent.get(server, fn state -> state end)
  end

  @doc """
  Reset with options.

      iex> alias LabLive.Data.Storage
      iex> {:ok, pid} = Storage.start_link(init: 10)
      iex> Storage.get(pid)
      10
      iex> Storage.reset(pid, [init: 20])
      iex> Storage.get(pid)
      20
  """
  @spec reset(GenServer.server(), opts()) :: :ok
  def reset(server, opts) do
    Agent.update(server, fn _ -> init_value(opts) end)
  end
end
