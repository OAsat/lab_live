defmodule LabLive.Data do
  @moduledoc """
  Agent server to hold data.
  """

  @type data() :: any()
  @type start_args() :: [data() | GenServer.options()]
  use Agent
  alias LabLive.Data.Protocol

  @spec start_link(start_args()) :: Agent.on_start()
  def start_link(opts) do
    Agent.start_link(fn -> opts[:init] end, opts)
  end

  @doc """
  Gets the raw data stored in the storage.

      iex> {:ok, pid} = LabLive.Data.start_link(init: 10)
      iex> LabLive.Data.get(pid)
      10

      iex> iter = LabLive.Data.Iterator.new([1, 2, 3])
      iex> {:ok, pid} = LabLive.Data.start_link(init: iter)
      iex> LabLive.Data.get(pid)
      %LabLive.Data.Iterator{count: :not_started, list: [1, 2, 3]}
  """
  @spec get(GenServer.server()) :: data()
  def get(server) do
    Agent.get(server, & &1)
  end

  @doc """
  Gets representative value of the stored data.

      iex> {:ok, pid} = LabLive.Data.start_link(init: 10)
      iex> LabLive.Data.value(pid)
      10

      iex> iter = LabLive.Data.Iterator.new([1, 2, 3])
      iex> {:ok, pid} = LabLive.Data.start_link(init: iter)
      iex> LabLive.Data.value(pid)
      :not_started
  """
  @spec value(GenServer.server()) :: any()
  def value(server) do
    get(server) |> Protocol.value()
  end

  @doc """
  Updates the storage with a new parameter.

      iex> {:ok, pid} = LabLive.Data.start_link(init: 10)
      iex> :ok = LabLive.Data.update(20, pid)
      iex> LabLive.Data.get(pid)
      20

      iex> iter = LabLive.Data.Iterator.new([1, 2, 3])
      iex> {:ok, pid} = LabLive.Data.start_link(init: iter)
      iex> :ok = LabLive.Data.update(pid)
      iex> LabLive.Data.value(pid)
      1
  """
  @spec update(GenServer.server()) :: :ok
  def update(server) do
    Agent.update(server, fn data -> Protocol.update(data, nil) end)
  end

  @spec update(any(), GenServer.server()) :: :ok
  def update(new, server) do
    Agent.update(server, fn data -> Protocol.update(data, new) end)
  end

  @doc """
  Overrides the storage with new data.

      iex> {:ok, pid} = LabLive.Data.start_link(init: 10)
      iex> :ok = LabLive.Data.override(20, pid)
      iex> LabLive.Data.get(pid)
      20
  """
  @spec override(data(), GenServer.server()) :: :ok
  def override(data, server) do
    Agent.update(server, fn _ -> data end)
  end
end
