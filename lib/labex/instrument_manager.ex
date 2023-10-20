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

  def start_instrument(key, inst_impl, opts) do
    name = get_via_name(key, inst_impl)
    DynamicSupervisor.start_child(@supervisor, {inst_impl, {name, opts}})
  end

  def start_instrument(key, model, inst_impl, opts) do
    name = get_via_name(key, inst_impl, model)
    DynamicSupervisor.start_child(@supervisor, {inst_impl, {name, opts}})
  end

  def start_instrument({key, inst_impl, opts}) do
    start_instrument(key, inst_impl, opts)
  end

  def start_instrument({key, model, inst_impl, opts}) do
    start_instrument(key, model, inst_impl, opts)
  end

  def start_instruments(list) when is_list(list) do
    list
    |> Enum.map(fn i -> start_instrument(i) end)
  end

  def lookup(key) do
    case Registry.lookup(@registry, key) do
      [] -> raise "Instrument #{key} not found."
      [{pid, {module, model}}] -> {pid, module, model}
      [{pid, module}] -> {pid, module}
    end
  end

  def get_via_name(key, module) do
    {:via, Registry, {@registry, key, module}}
  end

  def get_via_name(key, module, model) do
    {:via, Registry, {@registry, key, {module, model}}}
  end

  def read(key, query) when is_binary(query) do
    case lookup(key) do
      {pid, module, _model} -> module.read(pid, query)
      {pid, module} -> module.read(pid, query)
    end
  end

  def read(key, {model, variable, opts}) do
    {query, parser} = model.read(variable, opts)

    read(key, query) |> parser.()
  end

  def read(key, variable, opts \\ []) when is_atom(variable) do
    {_pid, _module, model} = lookup(key)
    read(key, {model, variable, opts})
  end

  def write(key, query) when is_binary(query) do
    case lookup(key) do
      {pid, module, _model} -> module.write(pid, query)
      {pid, module} -> module.write(pid, query)
    end
  end

  def write(key, {model, variable, opts}) do
    query = model.write(variable, opts)
    write(key, query)
  end

  def write(key, variable, opts \\ []) when is_atom(variable) do
    {_pid, _module, model} = lookup(key)
    write(key, {model, variable, opts})
  end
end
