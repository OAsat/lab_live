defmodule LabLive.Instrument.TcpTest do
  alias LabLive.Instrument
  alias LabLive.Instrument.Tcp
  use ExUnit.Case
  doctest Tcp

  test "tcp" do
    port = 8202
    {:ok, pid} = TestTcpServer.start_task(port)
    {:ok, inst_pid} = Instrument.start_link({:inst1, Tcp, address: ~c"localhost", port: port})

    assert Instrument.read(inst_pid, "Hello.") == "Hello."
    assert Instrument.read(inst_pid, "Hi.") == "Hi."

    Process.exit(pid, :normal)
  end
end
