defmodule Labex.Instrument.TcpInstrument do
  alias Labex.Instrument.Impl

  use GenServer
  @behaviour Impl
  @tcp_opts [:binary, packet: 0, active: false, reuseaddr: true]

  def get_name(key) do
    {:via, Registry, {Labex.Instrument.Registry, key}}
  end

  def start_link(key, address, port) do
    GenServer.start_link(__MODULE__, {address, port}, name: get_name(key))
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
  def read(message, key) do
    GenServer.call(get_name(key), {:read, message})
  end

  @impl Impl
  def write(message, key) do
    GenServer.cast(get_name(key), {:write, message})
  end
end
