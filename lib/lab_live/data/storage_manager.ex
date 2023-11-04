defmodule LabLive.Data.StorageManager do
  @moduledoc """
  Supervisor to manage properties by keys.
  """
  use Supervisor
  alias LabLive.Data.Storage

  @registry LabLive.Data.Storage.Registry
  @supervisor LabLive.Data.Storage.Supervisor

  @impl Supervisor
  def init(:ok) do
    children = [
      {DynamicSupervisor, name: @supervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: @registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec start_storage(map() | Keyword.t()) :: Keyword.t()
  def start_storage(storages) when is_list(storages) or is_map(storages) do
    for {name, opts} <- storages do
      {name, start_storage(name, opts)}
    end
  end

  @spec start_storage(atom(), Keyword.t()) :: DynamicSupervisor.on_start_child()
  def start_storage(name, opts \\ []) when is_atom(name) do
    via = {:via, Registry, {@registry, name, opts}}
    DynamicSupervisor.start_child(@supervisor, {Storage, [{:name, via} | opts]})
  end

  def info(key) do
    case Registry.lookup(@registry, key) do
      [] -> raise "Storage #{key} not found."
      [{pid, opts}] -> {pid, opts}
    end
  end

  def keys_and_pids() do
    Supervisor.which_children(@supervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      key = Registry.keys(@registry, pid) |> List.first()
      {key, pid}
    end)
  end
end
