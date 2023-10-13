defmodule Labex.StoreManager do
  alias Labex.Store
  use Supervisor

  @registry Labex.StoreRegistry
  @supervisor Labex.StoreSupervisor

  @impl Supervisor
  def init(_init_arg) do
    children = [
      {DynamicSupervisor, name: @supervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: @registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_agent(key) do
    name = via_name(key)
    DynamicSupervisor.start_child(@supervisor, {Labex.Store, {name, :undefined}})
  end

  def lookup(key) do
    [{pid, _}] = Registry.lookup(@registry, key)
    pid
  end

  def via_name(key) do
    {:via, Registry, {@registry, key}}
  end

  def get(key) do
    lookup(key) |> Store.get()
  end

  def set(key, value) do
    lookup(key) |> Store.set(value)
  end
end
