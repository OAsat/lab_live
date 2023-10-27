defmodule LabLive.Instrument.Tcp do
  alias LabLive.Instrument

  @behaviour Instrument
  @tcp_opts [:binary, packet: 0, active: false, reuseaddr: true]

  @impl Instrument
  def init(opts) do
    address = Keyword.get(opts, :address)
    port = Keyword.get(opts, :port)
    {address, port}
  end

  @impl Instrument
  def read(message, {address, port}) do
    socket = connect_and_send(message, address, port)
    {:ok, answer} = :gen_tcp.recv(socket, 0, 1000)
    {answer, socket}
  end

  @impl Instrument
  def after_reply(socket, _state) do
    :gen_tcp.close(socket)
  end

  @impl Instrument
  def write(message, {address, port}) do
    connect_and_send(message, address, port) |> :gen_tcp.close()

    :ok
  end

  defp connect_and_send(message, address, port) do
    {:ok, socket} = :gen_tcp.connect(address, port, @tcp_opts, 1000)
    :ok = :gen_tcp.send(socket, message)
    socket
  end
end
