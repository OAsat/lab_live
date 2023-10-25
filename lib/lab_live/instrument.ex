defmodule LabLive.Instrument do
  use Supervisor

  @registry LabLive.InstrumentRegistry
  @supervisor LabLive.InstrumentSupervisor

  @callback start_link({name :: GenServer.name(), opts :: any()}) :: any()
  @callback write(pid :: pid(), query :: String.t(), opts :: any()) :: any()
  @callback read(pid :: pid(), query :: String.t(), opts :: any()) :: String.t()

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

  defp lookup(inst) do
    case Registry.lookup(@registry, inst) do
      [] -> raise "Instrument #{inst} not found."
      [{pid, {module, model}}] -> {pid, module, model}
      [{pid, module}] -> {pid, module}
    end
  end

  defp get_via_name(key, module) do
    {:via, Registry, {@registry, key, module}}
  end

  defp get_via_name(key, module, model) do
    {:via, Registry, {@registry, key, {module, model}}}
  end

  def read(key, query) when is_binary(query) do
    case lookup(key) do
      {pid, module, _model} -> module.read(pid, query)
      {pid, module} -> module.read(pid, query)
    end
  end

  def read(inst, {model, query_key, opts}) do
    {query, parser} = model.read(query_key, opts)

    read(inst, query) |> parser.()
  end

  def read(inst, query_key, opts \\ []) when is_atom(query_key) do
    {_pid, _module, model} = lookup(inst)
    read(inst, {model, query_key, opts})
  end

  def write(inst, query) when is_binary(query) do
    case lookup(inst) do
      {pid, module, _model} -> module.write(pid, query)
      {pid, module} -> module.write(pid, query)
    end
  end

  def write(inst, {model, query_key, opts}) do
    query = model.write(query_key, opts)
    write(inst, query)
  end

  def write(inst, query_key, opts \\ []) when is_atom(query_key) do
    {_pid, _module, model} = lookup(inst)
    write(inst, {model, query_key, opts})
  end
end
