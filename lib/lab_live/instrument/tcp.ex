defmodule LabLive.Instrument.Tcp do
  alias LabLive.Instrument

  use GenServer
  @behaviour Instrument
  @tcp_opts [:binary, packet: 0, active: false, reuseaddr: true]

  @impl GenServer
  def init(opts) do
    {:ok, opts}
  end

  defp get_opts(opts) do
    address = Keyword.get(opts, :address)
    port = Keyword.get(opts, :port)
    sleep_after = Keyword.get(opts, :sleep_after, 0)
    {address, port, sleep_after}
  end

  @impl GenServer
  def handle_call({:read, message}, from, opts) do
    {address, port, sleep_after} = get_opts(opts)
    {:ok, socket} = :gen_tcp.connect(address, port, @tcp_opts, 1000)

    :ok = :gen_tcp.send(socket, message)
    {:ok, answer} = :gen_tcp.recv(socket, 0, 1000)

    GenServer.reply(from, answer)
    :gen_tcp.close(socket)

    if sleep_after > 0 do
      Process.sleep(sleep_after)
    end

    {:noreply, opts}
  end

  @impl GenServer
  def handle_cast({:write, message}, opts) do
    {address, port, sleep_after} = get_opts(opts)
    {:ok, socket} = :gen_tcp.connect(address, port, @tcp_opts, 1000)

    :ok = :gen_tcp.send(socket, message)
    :gen_tcp.close(socket)

    if sleep_after > 0 do
      Process.sleep(sleep_after)
    end

    {:noreply, opts}
  end

  @impl Instrument
  def start_link({name, opts}) do
    GenServer.start_link(__MODULE__, opts, name: name)
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
