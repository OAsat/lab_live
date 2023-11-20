defmodule LabLive.Connection.Method.TcpTest do
  alias LabLive.Connection.Method.Tcp
  alias LabLive.Connection
  use ExUnit.Case
  doctest Tcp

  test "read/2" do
    port = 8202
    {:ok, server} = TestTcpServer.start_task(port)

    opts = [address: [0, 0, 0, 0], port: 8202]
    {:ok, client} = start_supervised({Connection, method: Tcp, method_opts: opts})

    message = "Hello."
    assert ^message = Connection.read(client, message)

    Process.exit(server, :normal)
  end
end
