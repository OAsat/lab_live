defmodule Labex.InstrumentManager do
  use Supervisor

  @registry Labex.InstrumentRegistry
  @supervisor Labex.InstrumentSupervisor

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

  def start_instrument(key, module, opts) do
    name = get_via_name(key, module)
    DynamicSupervisor.start_child(@supervisor, {module, {name, opts}})
  end

  # def start_instrument(module, opts) do
  #   DynamicSupervisor.start_child(@supervisor, {module, opts})
  # end

  def lookup_instrument(key) do
    [{pid, module}] = Registry.lookup(@registry, key)
    {pid, module}
  end

  def get_via_name(key, module) do
    {:via, Registry, {@registry, key, module}}
  end

  def read(key, query) do
    {pid, module} = lookup_instrument(key)
    module.read(pid, query)
  end
  def write(key, query) do
    {pid, module} = lookup_instrument(key)
    module.write(pid, query)
  end
end
