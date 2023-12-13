defmodule LabLive.Data do
  @moduledoc """
  Agent id to hold data.
  """

  @type content() :: any()
  @type name() :: GenServer.name()
  @type start_opts() :: [init: content(), name: name()]
  use Agent, restart: :transient
  alias LabLive.Data.Protocol

  @spec start_link(start_opts()) :: Agent.on_start()
  def start_link(opts) do
    Agent.start_link(fn -> opts[:init] end, name: opts[:name])
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
  @spec get(pid()) :: content()
  def get(pid) do
    Agent.get(pid, & &1)
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
  @spec value(pid()) :: any()
  def value(pid) do
    get(pid) |> Protocol.value()
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
  @spec update(pid()) :: :ok
  def update(pid) do
    Agent.update(pid, fn data -> Protocol.update(data, nil) end)
  end

  @spec update(any(), pid()) :: :ok
  def update(new, pid) do
    Agent.update(pid, fn data -> Protocol.update(data, new) end)
  end

  @doc """
  Overrides the storage with new data.

      iex> {:ok, pid} = LabLive.Data.start_link(init: 10)
      iex> :ok = LabLive.Data.override(20, pid)
      iex> LabLive.Data.get(pid)
      20
  """
  @spec override(content(), pid()) :: :ok
  def override(data, pid) do
    Agent.update(pid, fn _ -> data end)
  end
end
