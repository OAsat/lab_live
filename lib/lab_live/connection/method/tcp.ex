defmodule LabLive.Connection.Method.Tcp do
  alias LabLive.Connection.Method
  @behaviour Method

  @type address() :: [non_neg_integer()]
  @type opt() :: {:address, address()} | {:port, non_neg_integer()}
  @type opts() :: [opt()]

  @tcp_opts [:binary, packet: 0, active: false, reuseaddr: true]

  @impl Method
  def init(opts) do
    {List.to_tuple(opts[:address]), opts[:port]}
  end

  @impl Method
  def read(message, {address, port}) do
    socket = connect_and_send(message, address, port)
    {:ok, answer} = :gen_tcp.recv(socket, 0, 1000)
    :gen_tcp.close(socket)
    answer
  end

  @impl Method
  def write(message, {address, port}) do
    connect_and_send(message, address, port) |> :gen_tcp.close()

    :ok
  end

  @impl Method
  def terminate(_reason, _resource) do
    :ok
  end

  defp connect_and_send(message, address, port) do
    {:ok, socket} = :gen_tcp.connect(address, port, @tcp_opts, 1000)
    :ok = :gen_tcp.send(socket, message)
    socket
  end
end
