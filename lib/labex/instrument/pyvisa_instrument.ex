defmodule Labex.Instrument.PyvisaInstrument do
  alias Labex.Instrument

  use GenServer
  @behaviour Instrument
  @python_src ~c"python/labex_pyvisa"

  @impl GenServer
  def init({python_exec, address}) do
    {:ok, {start_python(python_exec), python_exec, address}}
  end

  @impl GenServer
  def handle_call({:read, message}, _from, opts = {pid, _python_exec, address}) do
    answer = :python.call(pid, :communicate, :query, [address, message])
    {:reply, answer, opts}
  end

  @impl GenServer
  def handle_cast({:write, message}, opts = {pid, _python_exec, address}) do
    :python.call(pid, :communicate, :write, [address, message])
    {:noreply, opts}
  end

  @impl Instrument
  def start_link({name, python: python_exec, address: address}) do
    GenServer.start_link(__MODULE__, {python_exec, address}, name: name)
  end

  @impl Instrument
  def read(pid, message, _opts \\ nil) do
    GenServer.call(pid, {:read, message})
  end

  @impl Instrument
  def write(pid, message, _opts \\ nil) do
    GenServer.cast(pid, {:write, message})
  end

  defp start_python(python_exec) do
    {:ok, pid} =
      :python.start_link(python_path: @python_src, python: to_charlist(python_exec))

    pid
  end
end
