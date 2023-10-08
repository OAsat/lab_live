defmodule Labex.Instrument.DummyInstrument do
  alias Labex.Instrument

  use GenServer
  @behaviour Instrument

  @impl GenServer
  def init(opts) do
    {:ok, opts}
  end

  @impl GenServer
  def handle_call({:read, message}, _from, mapping) do
    %{^message => answer} = mapping
    {:reply, answer, mapping}
  end

  @impl GenServer
  def handle_cast({:write, _message}, mapping) do
    {:noreply, mapping}
  end

  @impl Instrument
  def start_link({name, mapping: mapping}) do
    GenServer.start_link(__MODULE__, mapping, name: name)
  end

  @impl Instrument
  def read(pid, message, _opts \\ nil) do
    GenServer.call(pid, {:read, message})
  end

  @impl Instrument
  def write(pid, message, _opts \\ nil) do
    GenServer.cast(pid, {:write, message})
  end
end
