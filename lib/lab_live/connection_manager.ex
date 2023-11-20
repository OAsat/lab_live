defmodule LabLive.ConnectionManager do
  @moduledoc """
  Supervisor to manage connection servers by keys.
  """
  alias LabLive.Connection
  use Supervisor

  @type manager() :: __MODULE__ | module() | atom()
  @type opts() :: [name: manager()]
  @type key() :: atom()
  @type info() :: any()
  @type on_start_instrument() :: {:ok, pid()} | {:reset, pid()} | {:error, term()}
  @type connection_opts() :: [
          {:sleep_after_reply, Connection.sleep_after_reply()}
          | {:method, Connection.method()}
          | {:method_opts, Connection.method_opts()}
        ]

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
          key :: key(),
          info :: info(),
          opts :: connection_opts()
        ) ::
          on_start_instrument()
  def start_instrument(manager \\ __MODULE__, key, info, connection_opts) do
    via = via_name(manager, key, info)

    case DynamicSupervisor.start_child(
           supervisor(manager),
           {Connection, [{:name, via} | connection_opts]}
         ) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Connection.reset(pid, connection_opts)
        {:reset, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec lookup(manager(), key()) :: {pid(), info()}
  def lookup(manager \\ __MODULE__, key) do
    case Registry.lookup(registry(manager), key) do
      [] -> raise "Instrument #{key} not found."
      [{pid, info}] -> {pid, info}
    end
  end

  @spec pid(manager(), key()) :: pid()
  def pid(manager \\ __MODULE__, key) do
    lookup(manager, key) |> elem(0)
  end

  @spec info(manager(), key()) :: info()
  def info(manager \\ __MODULE__, key) do
    lookup(manager, key) |> elem(1)
  end

  defp via_name(manager, key, info) do
    {:via, Registry, {registry(manager), key, info}}
  end

  @spec keys_and_pids(manager()) :: %{key() => pid()}
  def keys_and_pids(manager \\ __MODULE__) do
    Supervisor.which_children(supervisor(manager))
    |> Enum.map(fn {_, pid, _, _} ->
      key = Registry.keys(registry(manager), pid) |> List.first()
      {key, pid}
    end)
    |> Enum.into(%{})
  end
end
