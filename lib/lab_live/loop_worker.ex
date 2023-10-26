defmodule LabLive.LoopWorker do
  use GenServer, restart: :permanent

  def start_link({name, func, interval: interval}) do
    GenServer.start_link(__MODULE__, {func, interval}, name: name)
  end

  @impl GenServer
  def init({func, interval}) do
    run_loop(interval)
    {:ok, {true, func, interval}}
  end

  @impl GenServer
  def handle_info(:loop, {continue?, func, interval}) do
    if continue? do
      func.()
      run_loop(interval)
      {:noreply, {true, func, interval}}
    else
      {:noreply, {false, func, interval}}
    end
  end

  defp run_loop(interval) do
    Process.send_after(self(), :loop, interval)
  end

  def stop_loop(name) do
    GenServer.cast(name, :stop)
  end

  def start_loop(name) do
    GenServer.cast(name, :start)
  end

  @impl GenServer
  def handle_cast(:stop, {_, func, interval}) do
    {:noreply, {false, func, interval}}
  end

  @impl GenServer
  def handle_cast(:start, {_, func, interval}) do
    run_loop(interval)
    {:noreply, {true, func, interval}}
  end
end
