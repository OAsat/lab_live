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
      iex> props = %{b: [], c: [label: "label of c"]}
      iex> %{b: {:ok, _pid_b}, c: {:ok, _pid_c}} = start_properties(props)
      iex> opts(:c)
      [label: "label of c"]
      iex> update_many(%{b: 20, c: 30})
      %{b: :ok, c: :ok}
      iex> get_many([:b, :c])
      %{b: 20, c: 30}
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

  @spec start_property(atom(), Keyword.t()) :: DynamicSupervisor.on_start_child()
  def start_property(name, opts \\ []) do
    via = {:via, Registry, {@registry, name, opts}}
    DynamicSupervisor.start_child(@supervisor, {Property, via})
  end

  @spec start_properties(map()) :: %{
          atom() => DynamicSupervisor.on_start_child()
        }
  def start_properties(properties) do
    for {name, opts} <- properties do
      {name, start_property(name, opts)}
    end
    |> Enum.into(%{})
  end

  defp lookup(key) do
    case Registry.lookup(@registry, key) do
      [] -> raise "Variable #{key} not found."
      [{pid, opts}] -> {pid, opts}
    end
  end

  def opts(key) do
    lookup(key) |> elem(1)
  end

  @spec update(any(), atom()) :: any()
  def update(value, key) do
    lookup(key) |> elem(0) |> Property.update(value)
  end

  def update_many(keys_and_values) do
    for {key, value} <- keys_and_values do
      {key, update(value, key)}
    end
    |> Enum.into(%{})
  end

  @spec get(atom()) :: any()
  def get(key) do
    lookup(key) |> elem(0) |> Property.get()
  end

  def get_many(keys) do
    for key <- keys do
      {key, get(key)}
    end
    |> Enum.into(%{})
  end
end
