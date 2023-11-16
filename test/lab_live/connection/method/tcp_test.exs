defmodule LabLive.Connection.Method.TcpTest do
  alias LabLive.Connection.Method.Tcp
  use ExUnit.Case
  doctest Tcp

  test "tcp" do
    port = 8202
    {:ok, pid} = TestTcpServer.start_task(port)
    {answer, socket} = Tcp.read("Hello.", {~c"localhost", port})
    Tcp.after_reply(socket, nil)
    assert answer == "Hello."

    Process.exit(pid, :normal)
  end
end
