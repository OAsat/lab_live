defmodule LabLive.Instrument.PortManager do
  @moduledoc """
  Supervisor to manage instrument ports by keys.
  """
  alias LabLive.Instrument.Port
  alias LabLive.Instrument.Model
  use Supervisor

  @registry LabLive.Instrument.Port.Registry
  @supervisor LabLive.Instrument.Port.Supervisor

  @type opt() ::
          {:model, Model.t()}
          | {:type, LabLive.Instrument.Port.impl()}
          | LabLive.Instrument.Port.opt()

  @type opts() :: [opt()]

  @impl Supervisor
  def init(nil) do
    children = [
      {DynamicSupervisor,
       name: @supervisor,
       strategy: :one_for_one,
       max_restarts: Application.get_env(:lab_live, :max_restarts, 5)},
      {Registry, keys: :unique, name: @registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def start_link(_init_arg) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec start_instrument(key :: atom(), opts :: opts()) :: DynamicSupervisor.on_start_child()
  def start_instrument(key, opts) do
    name = via_name(key, opts[:model])

    case DynamicSupervisor.start_child(@supervisor, {Port, [{:name, name}, {:key, key} | opts]}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Port.reset(pid, opts)
        {:reset, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec start_instrument(instruments :: map() | Keyword.t()) :: map()
  def start_instrument(instruments) when is_map(instruments) or is_list(instruments) do
    for {key, opts} <- instruments do
      {key, start_instrument(key, opts)}
    end
    |> Enum.into(%{})
  end

  @spec info(atom()) :: {pid(), Model.t()}
  def info(inst) do
    case Registry.lookup(@registry, inst) do
      [] -> raise "Instrument #{inst} not found."
      [{pid, model}] -> {pid, model}
    end
  end

  @spec pid(atom()) :: pid()
  def pid(inst) do
    info(inst) |> elem(0)
  end

  @spec model(atom()) :: Model.t()
  def model(inst) do
    info(inst) |> elem(1)
  end

  defp via_name(key, model) do
    {:via, Registry, {@registry, key, model}}
  end

  def keys_and_pids() do
    Supervisor.which_children(@supervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      key = Registry.keys(@registry, pid) |> List.first()
      {key, pid}
    end)
  end
end
