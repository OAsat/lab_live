defmodule Labex.Instrument.TcpInstrument do
  alias Labex.Instrument.Impl

  use GenServer
  @behaviour Impl
  @tcp_opts [:binary, packet: 0, active: false, reuseaddr: true]

  def start_link(name, {address, port}) do
    GenServer.start_link(__MODULE__, {address, port}, name: name)
  end

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

  @impl Impl
  def read(message, pid: server) do
    GenServer.call(server, {:read, message})
  end

  @impl Impl
  def write(message, pid: server) do
    GenServer.cast(server, {:write, message})
  end
end
