defmodule LabLive.Instrument.TcpTest do
  alias LabLive.Instrument.Tcp
  use ExUnit.Case
  doctest Tcp

  test "tcp" do
    defmodule Server do
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
    end

    port = 8202
    {:ok, pid} = Task.start_link(fn -> Server.accept(port) end)

    {:ok, inst_pid} = Tcp.start_link({:inst1, address: ~c"localhost", port: port})

    assert Tcp.read(inst_pid, "Hello.") == "Hello."
    assert Tcp.read(inst_pid, "Hi.") == "Hi."

    Process.exit(pid, :normal)
  end
end
