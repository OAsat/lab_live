defmodule LabLive.Data do
  @moduledoc """
  Agent id to hold data.
  """

  @type content() :: any()
  @type name() :: GenServer.name()
  @type id() :: GenServer.server()
  @type data_spec() ::
          {:init, content()}
          | {:label, String.t()}
          | {:visible?, boolean()}
          | {:timeout, timeout()}
  @type data_specs() :: [data_spec()]
  @type start_opts() :: [{:name, name()} | data_spec()]
  use Agent
  alias LabLive.Data.Protocol

  @spec start_link(start_opts()) :: Agent.on_start()
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
  @spec get(id()) :: content()
  def get(id) do
    Agent.get(id, & &1)
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
  @spec value(id()) :: any()
  def value(id) do
    get(id) |> Protocol.value()
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
  @spec update(id()) :: :ok
  def update(id) do
    Agent.update(id, fn data -> Protocol.update(data, nil) end)
  end

  @spec update(any(), id()) :: :ok
  def update(new, id) do
    Agent.update(id, fn data -> Protocol.update(data, new) end)
  end

  @doc """
  Overrides the storage with new data.

      iex> {:ok, pid} = LabLive.Data.start_link(init: 10)
      iex> :ok = LabLive.Data.override(20, pid)
      iex> LabLive.Data.get(pid)
      20
  """
  @spec override(content(), id()) :: :ok
  def override(data, id) do
    Agent.update(id, fn _ -> data end)
  end
end
