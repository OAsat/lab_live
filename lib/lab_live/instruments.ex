defmodule LabLive.Instruments do
  @moduledoc """
  Supervisor to manage instruments by keys.

      iex> alias LabLive.Instrument.Dummy
      iex> {:ok, _pid} = LabLive.Instruments.start_instrument(:inst1, nil, {Dummy, map: %{"read" => "answer"}})
      iex> LabLive.Instruments.read(:inst1, "read")
      "answer"

  Starting multiple instruments:
      iex> alias LabLive.Instrument.Dummy
      iex> instruments = %{
      ...>     inst2: {nil, {Dummy, map: %{}}},
      ...>     inst3: {nil, {Dummy, map: %{}}}
      ...>   }
      iex> %{inst2: {:ok, _}, inst3: {:ok, _}} = LabLive.Instruments.start_instruments(instruments)
  """
  alias LabLive.Instrument
  use Supervisor

  @registry LabLive.InstrumentRegistry
  @supervisor LabLive.InstrumentSupervisor

  @impl Supervisor
  def init(nil) do
    children = [
      {DynamicSupervisor, name: @supervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: @registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def start_link(_init_arg) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_instrument(key, model, {inst, opts}) do
    name = via_name(key, model)
    DynamicSupervisor.start_child(@supervisor, {Instrument, {name, inst, opts}})
  end

  def start_instruments(map) when is_map(map) do
    for {key, inst_info} <- map do
      {model, {inst, opts}} = inst_info
      {key, start_instrument(key, model, {inst, opts})}
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
      {pid, _model} -> Instrument.read(pid, query)
    end
  end

  def read(key, query_key, opts) when is_atom(query_key) and is_list(opts) do
    {pid, model} = lookup(key)
    Instrument.read(pid, model, query_key, opts)
  end

  def read_joined(key, query_keys_and_opts) when is_list(query_keys_and_opts) do
    {pid, model} = lookup(key)
    Instrument.read_joined(pid, model, query_keys_and_opts)
  end

  def write(key, query) when is_binary(query) do
    case lookup(key) do
      {pid, _model} -> Instrument.write(pid, query)
    end
  end

  def write(key, query_key, opts) when is_atom(query_key) and is_list(opts) do
    {pid, model} = lookup(key)
    Instrument.write(pid, model, query_key, opts)
  end

  def write_joined(key, query_keys_and_opts) when is_list(query_keys_and_opts) do
    {pid, model} = lookup(key)
    Instrument.write_joined(pid, model, query_keys_and_opts)
  end
end
