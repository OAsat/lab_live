defmodule LabLive.Execution.Worker do
  @moduledoc """
  Worker to run execution diagram.
  """
  use GenServer
  alias LabLive.Data
  alias LabLive.Data.Iterator

  defmodule State do
    @moduledoc false
    defstruct diagram: [], stack: [], run?: false
  end

  @type state :: %State{
          diagram: list(),
          stack: list(),
          run?: boolean()
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl GenServer
  def init(nil) do
    {:ok, LabLive.Execution.Stash.get()}
  end

  @impl GenServer
  def terminate(_reason, state) do
    update_stash(state)
  end

  @impl GenServer
  def handle_cast({:set_diagram, diagram}, _state) do
    new_state = %State{diagram: diagram, stack: diagram}
    {:noreply, new_state |> on_update()}
  end

  @impl GenServer
  def handle_cast(:start, state) do
    send_after(0)

    {:noreply, %{state | run?: true} |> on_update()}
  end

  @impl GenServer
  def handle_cast(:pause, state) do
    {:noreply, %{state | run?: false} |> on_update()}
  end

  @impl GenServer
  def handle_cast(:reset, %State{diagram: diagram} = state) do
    {:noreply, %State{state | stack: diagram, run?: false} |> on_update()}
  end

  @impl GenServer
  def handle_info(:run, state) do
    update_stash(state)
    next = run_step(state)
    on_update(next)
    if next.run?, do: send_after(0)

    {:noreply, next}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @spec set_diagram(GenServer.name(), list()) :: :ok
  def set_diagram(name \\ __MODULE__, diagram) do
    GenServer.cast(name, {:set_diagram, diagram})
  end

  @spec start_run(GenServer.name()) :: :ok
  def start_run(name \\ __MODULE__) do
    GenServer.cast(name, :start)
  end

  @spec pause(GenServer.name()) :: :ok
  def pause(name \\ __MODULE__) do
    GenServer.cast(name, :pause)
  end

  @spec reset(GenServer.name()) :: :ok
  def reset(name \\ __MODULE__) do
    GenServer.cast(name, :reset)
  end

  @spec get_state(GenServer.name()) :: state()
  def get_state(name \\ __MODULE__) do
    GenServer.call(name, :get_state)
  end

  defp send_after(interval) do
    Process.send_after(self(), :run, interval)
  end

  defp update_stash(state) do
    LabLive.Execution.Stash.update(state)
  end

  defp on_update(%State{} = state) do
    update_stash(state)

    :telemetry.execute(
      [:lab_live, :execution, :update_state],
      %{state: state}
    )

    state
  end

  defp run_step(%State{stack: []} = state) do
    %State{state | run?: false}
  end

  defp run_step(%State{stack: [function | tail]} = state) when is_function(function, 0) do
    function.()
    %State{state | stack: tail}
  end

  defp run_step(%State{stack: [{module, function_name} | tail]} = state)
       when is_atom(module) and is_atom(function_name) do
    Kernel.apply(module, function_name, [])
    %State{state | stack: tail}
  end

  defp run_step(%State{stack: [{module, function_name, args} | tail]} = state)
       when is_atom(module) and is_atom(function_name) and is_list(args) do
    Kernel.apply(module, function_name, args)
    %State{state | stack: tail}
  end

  defp run_step(%State{stack: [iterate: key, do: iteration]} = state) do
    %State{state | stack: [[iterate: key, do: iteration]]}
  end

  defp run_step(%State{stack: [[iterate: key, do: iteration] | tail]} = state) do
    set_iteration = fn ->
      Data.get(key) |> Iterator.reset() |> Data.override(key)
      Data.update(key)
    end

    iterating = [iterating: key, do: iteration]
    %State{state | stack: [set_iteration, iteration, iterating] ++ tail}
  end

  defp run_step(%State{stack: [[iterating: key, do: iteration] | tail]} = state) do
    Data.update(key)

    if Data.get(key) |> Iterator.finish?() do
      %State{state | stack: tail}
    else
      %State{state | stack: [iteration, [iterating: key, do: iteration]] ++ tail}
    end
  end
end
