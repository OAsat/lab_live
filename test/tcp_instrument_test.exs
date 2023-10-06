defmodule TcpInstrumentTest do
  alias Labex.Instrument.TcpInstrument
  use ExUnit.Case
  doctest TcpInstrument

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

    defmodule MyModel do
      use Labex.Instrument.Model

      def_read(:kelvin, "KRDG? ~s", "~s")
    end

    port = 8202
    {:ok, pid} = Task.start_link(fn -> Server.accept(port) end)

    {:ok, inst_pid} = TcpInstrument.start_link(:inst1, {~c"localhost", port})

    assert TcpInstrument.read("Hello.", pid: inst_pid) == "Hello."
    assert TcpInstrument.read("Hi.", pid: inst_pid) == "Hi."
    assert MyModel.read(:kelvin, ["A"], {TcpInstrument, pid: inst_pid}) == ["KRDG? A"]

    Process.exit(pid, :normal)
  end
end
