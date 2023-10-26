defmodule LabLive.Variables do
  @moduledoc """
  Supervisor to manage properties by keys.

      iex> import LabLive.Variables
      iex> properties = %{a: fn -> 1 end, b: fn x -> x + 1 end}
      iex> start_properties(properties)
      iex> update(:a)
      1
      iex> get(:a)
      1
      iex> update(:b, 1)
      2
      iex> get(:b)
      2
  """
  use Supervisor
  alias LabLive.Property

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

  @spec start_property(atom(), function()) :: DynamicSupervisor.on_start_child()
  def start_property(name, function) do
    via = via_name(name, Property)
    DynamicSupervisor.start_child(@supervisor, {Property, {via, function}})
  end

  @spec start_properties(%{atom() => function()}) :: %{
          atom() => DynamicSupervisor.on_start_child()
        }
  def start_properties(map) do
    for {name, function} <- map do
      {name, start_property(name, function)}
    end
    |> Enum.into(%{})
  end

  defp lookup(key) do
    case Registry.lookup(@registry, key) do
      [] -> raise "Variable #{key} not found."
      [{pid, value}] -> {pid, value}
    end
  end

  defp via_name(key, value) do
    {:via, Registry, {@registry, key, value}}
  end

  @spec update(atom()) :: any()
  def update(key) do
    case lookup(key) do
      {pid, Property} -> Property.update(pid)
      {_pid, module} -> raise "Variable #{key} is not a property. It is a #{module}."
    end
  end

  @spec update(atom(), any()) :: any()
  def update(key, args) do
    case lookup(key) do
      {pid, Property} -> Property.update(pid, args)
      {_pid, module} -> raise "Variable #{key} is not a property. It is a #{module}."
    end
  end

  @spec get(atom()) :: any()
  def get(key) do
    case lookup(key) do
      {pid, Property} -> Property.get(pid)
      {_pid, module} -> raise "Variable #{key} is not a property. It is a #{module}."
    end
  end
end
