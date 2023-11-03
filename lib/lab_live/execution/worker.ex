defmodule LabLive.Execution.Worker do
  @moduledoc """
  Worker to run execution diagram.
  """
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct diagram: %{}, status: :start, idle?: true
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(nil) do
    send_after(0)
    {:ok, LabLive.Execution.Stash.get()}
  end

  @impl GenServer
  def terminate(_reason, state) do
    LabLive.Execution.Stash.update(state)
  end

  @impl GenServer
  def handle_cast({:set_diagram, diagram}, _state) do
    new_state = %State{diagram: diagram}
    telemetry_update_state(new_state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast(:start, state) do
    send_after(0)
    {:noreply, %{state | idle?: false}}
  end

  @impl GenServer
  def handle_cast(:pause, state) do
    {:noreply, %{state | idle?: true}}
  end

  @impl GenServer
  def handle_info(:run, state) do
    if state.idle? do
      {:noreply, state}
    else
      telemetry_update_state(state)
      {:noreply, run(state)}
    end
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @spec set_diagram(map()) :: :ok
  def set_diagram(diagram) do
    GenServer.cast(__MODULE__, {:set_diagram, diagram})
  end

  @spec start() :: :ok
  def start() do
    GenServer.cast(__MODULE__, :start)
  end

  @spec pause() :: :ok
  def pause() do
    GenServer.cast(__MODULE__, :pause)
  end

  @spec get_state() :: any()
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  defp send_after(interval) do
    Process.send_after(self(), :run, interval)
  end

  defp telemetry_update_state(state) do
    :telemetry.execute([:lab_live, :execution, :update_state], %{state: state})
  end

  defp run(%State{status: :start} = state) do
    next = state.diagram[:start]
    send_after(0)
    %{state | status: next}
  end

  defp run(%State{status: :finish} = state) do
    %{state | idle?: true}
  end

  defp run(%State{status: {module, function}} = state)
       when is_atom(module) and is_atom(function) do
    Kernel.apply(module, function, [])
    next = state.diagram[state.status]
    send_after(100)
    %{state | status: next}
  end

  defp run(%State{status: [f: function, str: _, branch: branch]} = state)
       when is_function(function, 0) do
    next = branch[function.()]
    send_after(0)
    %{state | status: next}
  end
end
