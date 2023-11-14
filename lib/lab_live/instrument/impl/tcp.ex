defmodule LabLive.Instrument.Impl.Tcp do
  alias LabLive.Instrument.Impl
  @behaviour Impl

  @tcp_opts [:binary, packet: 0, active: false, reuseaddr: true]

  @impl Impl
  def init(opts) do
    {List.to_tuple(opts[:address]), opts[:port]}
  end

  @impl Impl
  def read(message, {address, port}) do
    socket = connect_and_send(message, address, port)
    {:ok, answer} = :gen_tcp.recv(socket, 0, 1000)
    {answer, socket}
  end

  @impl Impl
  def after_reply(socket, _state) do
    :gen_tcp.close(socket)
  end

  @impl Impl
  def write(message, {address, port}) do
    connect_and_send(message, address, port) |> :gen_tcp.close()

    :ok
  end

  @impl Impl
  def terminate(_reason, _resource) do
    :ok
  end

  defp connect_and_send(message, address, port) do
    {:ok, socket} = :gen_tcp.connect(address, port, @tcp_opts, 1000)
    :ok = :gen_tcp.send(socket, message)
    socket
  end
end
