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
    Registry.start_link(keys: :unique, name: Labex.InstrumentRegistry)
    TcpInstrument.start_link(:inst1, {~c"localhost", port})

    assert TcpInstrument.read("Hello from client.", :inst1) == "Hello from client."
    assert TcpInstrument.read("Hello from client.", :inst1) == "Hello from client."
    assert MyModel.read(:kelvin, ["A"], {TcpInstrument, :inst1}) == ["KRDG? A"]
    Process.exit(pid, :normal)
  end
end
