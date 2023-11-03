defmodule LabLive.Execution do
  defstruct diagram: %{}, status: :start, idle?: true
  use GenServer

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
    new_state = %LabLive.Execution{diagram: diagram}
    :telemetry.execute([:lab_live, :execution, :update_status], %{exec_state: new_state})
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
      :telemetry.execute([:lab_live, :execution, :update_status], %{exec_state: state})
      run(state)
    end
  end

  defp run(%LabLive.Execution{status: :start} = state) do
    next = state.diagram[:start]
    send_after(0)
    {:noreply, %{state | status: next}}
  end

  defp run(%LabLive.Execution{status: {module, function}} = state)
       when is_atom(module) and is_atom(function) do
    Kernel.apply(module, function, [])
    next = state.diagram[state.status]
    send_after(100)
    {:noreply, %{state | status: next}}
  end

  defp run(%LabLive.Execution{status: [f: function, str: _, branch: branch]} = state)
       when is_function(function, 0) do
    next = branch[function.()]
    send_after(0)
    {:noreply, %{state | status: next}}
  end

  @impl GenServer
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def set_diagram(diagram) do
    GenServer.cast(__MODULE__, {:set_diagram, diagram})
  end

  def start() do
    GenServer.cast(__MODULE__, :start)
  end

  def pause() do
    GenServer.cast(__MODULE__, :pause)
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  defp send_after(interval) do
    Process.send_after(self(), :run, interval)
  end
end
