defmodule LabLive.Variable do
  use Supervisor
  alias LabLive.Setter
  alias LabLive.Getter

  @registry LabLive.VariableRegistry
  @supervisor LabLive.VariableSupervisor

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

  @spec start_setter(atom(), function()) :: DynamicSupervisor.on_start_child()
  def start_setter(name, setter) do
    via = via_name(name)
    DynamicSupervisor.start_child(@supervisor, {Setter, {via, setter}})
  end

  @spec start_setters(%{atom() => function()}) :: %{atom() => DynamicSupervisor.on_start_child()}
  def start_setters(map) do
    for {name, setter} <- map do
      {name, start_setter(name, setter)}
    end
    |> Enum.into(%{})
  end

  @spec start_getter(atom(), function()) :: DynamicSupervisor.on_start_child()
  def start_getter(name, getter) do
    via = via_name(name)
    DynamicSupervisor.start_child(@supervisor, {Getter, {via, getter}})
  end

  @spec start_getters(%{atom() => function()}) :: %{atom() => DynamicSupervisor.on_start_child()}
  def start_getters(map) do
    for {name, getter} <- map do
      {name, start_getter(name, getter)}
    end
    |> Enum.into(%{})
  end

  defp lookup(key) do
    case Registry.lookup(@registry, key) do
      [] -> raise "Variable #{key} not found."
      [{pid, _}] -> pid
    end
  end

  defp via_name(key) do
    {:via, Registry, {@registry, key}}
  end

  def get(key) do
    lookup(key) |> Getter.get()
  end

  def set(key, value) do
    lookup(key) |> Setter.set(value)
  end
end
