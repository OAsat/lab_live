defmodule LabLive.Storage do
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
  """
  @spec get(pid()) :: content()
  def get(pid) do
    Agent.get(pid, & &1)
  end

  @doc """
  Gets representative value of the stored data.
  """
  @spec value(pid()) :: any()
  def value(pid) do
    get(pid) |> Protocol.value()
  end

  @doc """
  Updates the storage with a new parameter.
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
  """
  @spec override(content(), pid()) :: :ok
  def override(data, pid) do
    Agent.update(pid, fn _ -> data end)
  end
end
