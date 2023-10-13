defmodule Labex.InstrumentManager do
  alias Labex.Utils.Format
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

  def lookup(key) do
    [{pid, module}] = Registry.lookup(@registry, key)
    {pid, module}
  end

  def get_via_name(key, module) do
    {:via, Registry, {@registry, key, module}}
  end

  def read(key, query) when is_binary(query) do
    {pid, module} = lookup(key)
    module.read(pid, query)
  end

  def read(key, {model, variable, param_list}) when is_atom(variable) do
    {query_fmt, answer_fmt} = model.read(variable)
    query = Format.format_query(query_fmt, param_list)

    read(key, query)
    |> Format.parse_answer(answer_fmt)
  end

  def write(key, query) when is_binary(query) do
    {pid, module} = lookup(key)
    module.write(pid, query)
  end

  def write(key, {model, variable, param_list}) when is_atom(variable) do
    query_fmt = model.write(variable)
    query = Format.format_query(query_fmt, param_list)
    write(key, query)
  end
end
