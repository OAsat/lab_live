defmodule LabLive.Instrument.PortManager do
  @moduledoc """
  Supervisor to manage instrument ports by keys.
  """
  alias LabLive.Instrument.Port
  use Supervisor

  @type manager() :: __MODULE__ | module() | atom()
  @type opts() :: [name: manager()]
  @type port_key() :: atom()
  @type port_info() :: any()
  @type on_start_instrument() :: {:ok, pid()} | {:reset, pid()} | {:error, term()}

  @impl Supervisor
  def init(name) do
    children = [
      {DynamicSupervisor,
       name: supervisor(name),
       strategy: :one_for_one,
       max_restarts: Application.get_env(:lab_live, :max_restarts, 5)},
      {Registry, keys: :unique, name: registry(name)}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp supervisor(name) do
    :"#{name}.Supervisor"
  end

  defp registry(name) do
    :"#{name}.Registry"
  end

  @spec start_link(opts()) :: Supervisor.on_start()
  def start_link(opts) do
    name = opts[:name] || __MODULE__
    Supervisor.start_link(__MODULE__, name, name: name)
  end

  @spec start_instrument(
          manager :: manager(),
          port_key :: port_key(),
          port_info :: port_info(),
          port_opts :: Port.opts()
        ) ::
          on_start_instrument()
  def start_instrument(manager \\ __MODULE__, port_key, port_info, port_opts) do
    via = via_name(manager, port_key, port_info)

    case DynamicSupervisor.start_child(supervisor(manager), {Port, [{:name, via} | port_opts]}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Port.reset(pid, port_opts)
        {:reset, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec lookup(manager(), port_key()) :: {pid(), port_info()}
  def lookup(manager \\ __MODULE__, port_key) do
    case Registry.lookup(registry(manager), port_key) do
      [] -> raise "Instrument #{port_key} not found."
      [{pid, info}] -> {pid, info}
    end
  end

  @spec pid(manager(), port_key()) :: pid()
  def pid(manager \\ __MODULE__, port_key) do
    lookup(manager, port_key) |> elem(0)
  end

  @spec info(manager(), port_key()) :: port_info()
  def info(manager \\ __MODULE__, port_key) do
    lookup(manager, port_key) |> elem(1)
  end

  defp via_name(manager, port_key, port_info) do
    {:via, Registry, {registry(manager), port_key, port_info}}
  end

  @spec keys_and_pids(manager()) :: %{port_key() => pid()}
  def keys_and_pids(manager \\ __MODULE__) do
    Supervisor.which_children(supervisor(manager))
    |> Enum.map(fn {_, pid, _, _} ->
      key = Registry.keys(registry(manager), pid) |> List.first()
      {key, pid}
    end)
    |> Enum.into(%{})
  end
end
