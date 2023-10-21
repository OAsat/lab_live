defmodule LabLive.VariableManager do
  alias LabLive.Variable
  use Supervisor

  @registry LabLive.VariableRegistry
  @supervisor LabLive.VariableSupervisor

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
    DynamicSupervisor.start_child(@supervisor, {Variable, {name, :undefined}})
  end

  def lookup(key) do
    [{pid, _}] = Registry.lookup(@registry, key)
    pid
  end

  def via_name(key) do
    {:via, Registry, {@registry, key}}
  end

  def get(key) do
    lookup(key) |> Variable.latest()
  end

  def set(key, value) do
    lookup(key) |> Variable.append(value)
  end
end
