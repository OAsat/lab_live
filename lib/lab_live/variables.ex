defmodule LabLive.Variables do
  @moduledoc """
  Supervisor to manage properties by keys.

      iex> import LabLive.Variables
      iex> {:ok, _pid} = start_property(:a)
      iex> 10 |> update(:a)
      :ok
      iex> get(:a)
      10

  Starting multiple properties:
      iex> import LabLive.Variables
      iex> %{b: {:ok, _pid_b}, c: {:ok, _pid_c}} = start_properties([:b, :c])
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

  @spec start_property(atom()) :: DynamicSupervisor.on_start_child()
  def start_property(name) do
    via = {:via, Registry, {@registry, name}}
    DynamicSupervisor.start_child(@supervisor, {Property, via})
  end

  @spec start_properties(list(atom())) :: %{
          atom() => DynamicSupervisor.on_start_child()
        }
  def start_properties(names) when is_list(names) do
    for name <- names do
      {name, start_property(name)}
    end
    |> Enum.into(%{})
  end

  defp lookup(key) do
    case Registry.lookup(@registry, key) do
      [] -> raise "Variable #{key} not found."
      [{pid, _}] -> pid
    end
  end

  @spec update(any(), atom()) :: any()
  def update(value, key) do
    lookup(key) |> Property.update(value)
  end

  @spec get(atom()) :: any()
  def get(key) do
    lookup(key) |> Property.get()
  end
end
