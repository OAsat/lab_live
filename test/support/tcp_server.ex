defmodule TestTcpServer do
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: 0, active: false, reuseaddr: true])

    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read()
    |> write(socket)
  end

  defp read(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write(line, socket) do
    :ok = :gen_tcp.send(socket, line)
  end

  def start_task(port) do
    Task.start_link(fn -> accept(port) end)
  end
end
