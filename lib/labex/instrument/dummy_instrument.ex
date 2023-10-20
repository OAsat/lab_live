defmodule LabLive.Instrument.DummyInstrument do
  alias LabLive.Instrument

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
  def handle_cast({:write, message}, mapping) do
    if not Map.has_key?(mapping, message) do
      raise "Write message #{message} not expected."
    end

    {:noreply, mapping}
  end

  @impl Instrument
  def start_link({name, map: map}) do
    GenServer.start_link(__MODULE__, map, name: name)
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
