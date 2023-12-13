defmodule LabLive.DataManager do
  @moduledoc """
  Supervisor to manage data servers by keys.
  """
  alias LabLive.Data
  alias LabLive.DataInfo
  use Supervisor

  @type opts() :: [name: manager()]
  @type key() :: atom()
  @type data() :: Data.content()
  @type info() :: DataInfo.t()
  @type on_start_data() :: {:ok, pid()} | {:reset, pid()} | {:error, term()}
  @type manager() :: __MODULE__ | module() | atom()

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

  @spec start_data(manager :: manager(), key :: key(), data :: data(), info :: info()) ::
          on_start_data()
  def start_data(manager \\ __MODULE__, key, data, info) do
    case start_supervised_data(manager, key, data, info) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        GenServer.stop(pid, :normal)
        {:ok, new_pid} = start_supervised_data(manager, key, data, info)
        {:restart, new_pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp start_supervised_data(manager, key, data, info) do
    via = via_name(manager, key, info)
    DynamicSupervisor.start_child(supervisor(manager), {Data, [name: via, init: data]})
  end

  @spec lookup(manager(), key()) :: {pid(), info()}
  def lookup(manager \\ __MODULE__, key) do
    case Registry.lookup(registry(manager), key) do
      [] -> {:error, "Data storage #{key} not found."}
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
