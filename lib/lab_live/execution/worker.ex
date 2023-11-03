defmodule LabLive.Execution.Worker do
  @moduledoc """
  Worker to run execution diagram.
  """
  use GenServer
  alias LabLive.Execution.Diagram

  defmodule State do
    @moduledoc false
    defstruct diagram: %{}, status: :start, idle?: true
  end

  @type state :: %State{
          diagram: Diagram.diagram(),
          status: Diagram.stage(),
          idle?: boolean()
        }

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
      {:noreply, run_step(state)}
    end
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @spec set_diagram(Diagram.diagram()) :: :ok
  def set_diagram(diagram) do
    GenServer.cast(__MODULE__, {:set_diagram, diagram})
  end

  @spec start_run() :: :ok
  def start_run() do
    GenServer.cast(__MODULE__, :start)
  end

  @spec pause() :: :ok
  def pause() do
    GenServer.cast(__MODULE__, :pause)
  end

  @spec get_state() :: state()
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  defp send_after(interval) do
    Process.send_after(self(), :run, interval)
  end

  defp telemetry_update_state(state) do
    :telemetry.execute([:lab_live, :execution, :update_state], %{state: state})
  end

  defp run_step(%State{} = state) do
    case Diagram.run_step(state.diagram, state.status) do
      :finish ->
        %State{state | status: :finish, idle?: true}

      next ->
        send_after(0)
        %State{state | status: next}
    end
  end
end
