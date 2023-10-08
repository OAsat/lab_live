defmodule Labex.Instrument.TcpInstrument do
  alias Labex.Instrument

  use GenServer
  @behaviour Instrument
  @tcp_opts [:binary, packet: 0, active: false, reuseaddr: true]

  @impl GenServer
  def init(opts) do
    {:ok, opts}
  end

  @impl GenServer
  def handle_call({:read, message}, _from, opts = {address, port}) do
    {:ok, socket} = :gen_tcp.connect(address, port, @tcp_opts, 1000)

    :ok = :gen_tcp.send(socket, message)
    {:ok, answer} = :gen_tcp.recv(socket, 0, 1000)
    :gen_tcp.close(socket)
    {:reply, answer, opts}
  end

  @impl GenServer
  def handle_cast({:write, message}, opts = {address, port}) do
    {:ok, socket} = :gen_tcp.connect(address, port, @tcp_opts, 1000)

    :ok = :gen_tcp.send(socket, message)
    :gen_tcp.close(socket)
    {:noreply, opts}
  end

  @impl Instrument
  def start_link({name, address: address, port: port}) do
    GenServer.start_link(__MODULE__, {address, port}, name: name)
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
