defmodule LabLive.Instrument.PortManager do
  @moduledoc """
  Supervisor to manage instrument ports by keys.

      iex> import LabLive.Instrument.PortManager
      iex> alias LabLive.Instrument.Impl.Dummy
      iex> {:ok, _pid} = start_instrument(:inst1, [model: Lakeshore350, type: Dummy, map: Lakeshore350.dummy()])
      iex> read(:inst1, "SETP? 2\\n")
      "1.0\\r\\n"
      iex> read(:inst1, :setp, channel: 2)
      %{kelvin: 1.0}
      iex> read_joined(:inst1, sensor: [channel: "A"], sensor: [channel: "C"], heater: [channel: 2])
      [sensor: %{ohm: 1200.0}, sensor: %{ohm: 0.23}, heater: %{percentage: 56.7}]

  Starting multiple instruments:
      iex> import LabLive.Instrument.PortManager
      iex> alias LabLive.Instrument.Impl.Dummy
      iex> instruments = [
      ...>     inst2: [type: Dummy, map: %{}],
      ...>     inst3: [type: Dummy, map: %{}]
      ...>   ]
      iex> %{inst2: {:ok, _}, inst3: {:ok, _}} = start_instrument(instruments)
  """
  alias LabLive.Instrument.Port
  use Supervisor

  @registry LabLive.Instrument.Port.Registry
  @supervisor LabLive.Instrument.Port.Supervisor

  @type model() :: module()

  @type opt() ::
          {:model, model()}
          | {:type, LabLive.Instrument.Port.impl()}
          | LabLive.Instrument.Port.opt()

  @type opts() :: [opt()]

  @impl Supervisor
  def init(nil) do
    children = [
      {DynamicSupervisor, name: @supervisor, strategy: :one_for_one, max_restarts: 50},
      {Registry, keys: :unique, name: @registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def start_link(_init_arg) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_instrument(key, opts) do
    name = via_name(key, opts[:model])
    DynamicSupervisor.start_child(@supervisor, {Port, [{:name, name}, {:key, key} | opts]})
  end

  def start_instrument(instruments) when is_map(instruments) or is_list(instruments) do
    for {key, opts} <- instruments do
      {key, start_instrument(key, opts)}
    end
    |> Enum.into(%{})
  end

  defp lookup(inst) do
    case Registry.lookup(@registry, inst) do
      [] -> raise "Instrument #{inst} not found."
      [{pid, model}] -> {pid, model}
    end
  end

  defp via_name(key, model) do
    {:via, Registry, {@registry, key, model}}
  end

  def read(key, query) when is_binary(query) do
    case lookup(key) do
      {pid, _model} -> Port.read(pid, query)
    end
  end

  def read(key, query_key, opts \\ []) when is_atom(query_key) and is_list(opts) do
    {pid, model} = lookup(key)
    Port.read(pid, model, query_key, opts)
  end

  def read_joined(key, query_keys_and_opts) when is_list(query_keys_and_opts) do
    {pid, model} = lookup(key)
    Port.read_joined(pid, model, query_keys_and_opts)
  end

  def write(key, query) when is_binary(query) do
    case lookup(key) do
      {pid, _model} -> Port.write(pid, query)
    end
  end

  def write(key, query_key, opts \\ []) when is_atom(query_key) and is_list(opts) do
    {pid, model} = lookup(key)
    Port.write(pid, model, query_key, opts)
  end

  def write_joined(key, query_keys_and_opts) when is_list(query_keys_and_opts) do
    {pid, model} = lookup(key)
    Port.write_joined(pid, model, query_keys_and_opts)
  end
end
