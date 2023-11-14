defmodule LabLive.Instrument.PortManager do
  @moduledoc """
  Supervisor to manage instrument ports by keys.
  """
  alias LabLive.Instrument.Port
  alias LabLive.Instrument.Model
  use Supervisor

  @type opt() ::
          {:model, Model.t()}
          | {:type, LabLive.Instrument.Port.impl()}
          | LabLive.Instrument.Port.opt()

  @type info() :: %{model: Model.t()}
  @type opts() :: [opt()]
  @type on_start_instrument() :: {:ok, pid()} | {:reset, pid()} | {:error, term()}

  @impl Supervisor
  def init(name \\ __MODULE__) do
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

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts[:name], opts)
  end

  @spec start_instrument(name :: atom(), key :: atom(), info :: info(), opts :: opts()) ::
          on_start_instrument()
  def start_instrument(name \\ __MODULE__, key, info, opts) do
    via = via_name(name, key, info)

    case DynamicSupervisor.start_child(supervisor(name), {Port, [{:name, via} | opts]}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Port.reset(pid, opts)
        {:reset, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec lookup(atom()) :: {pid(), info()}
  def lookup(name \\ __MODULE__, inst) do
    case Registry.lookup(registry(name), inst) do
      [] -> raise "Instrument #{inst} not found."
      [{pid, model}] -> {pid, model}
    end
  end

  @spec pid(atom()) :: pid()
  def pid(name \\ __MODULE__, inst) do
    lookup(name, inst) |> elem(0)
  end

  @spec info(atom()) :: info()
  def info(name \\ __MODULE__, inst) do
    lookup(name, inst) |> elem(1)
  end

  defp via_name(name, key, info) do
    {:via, Registry, {registry(name), key, info}}
  end

  def keys_and_pids(name \\ __MODULE__) do
    Supervisor.which_children(supervisor(name))
    |> Enum.map(fn {_, pid, _, _} ->
      key = Registry.keys(registry(name), pid) |> List.first()
      {key, pid}
    end)
    |> Enum.into(%{})
  end
end
