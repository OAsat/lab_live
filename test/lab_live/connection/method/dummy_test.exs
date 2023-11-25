defmodule LabLive.Connection.Method.DummyTest do
  use ExUnit.Case
  alias LabLive.Connection.Method.Dummy
  alias LabLive.Connection
  alias LabLive.Model
  doctest Dummy

  test "read/2" do
    model = %Model{
      query: %{
        sample: %{input: "SAMPLE", output: "{{val1:str}},{{val2:float}},{{val3:int}}"}
      }
    }

    opts = [model: model]
    {:ok, pid} = start_supervised({Connection, method: Dummy, method_opts: opts})
    assert "dummy,1.0,1\n" == Connection.read(pid, "SAMPLE\n")
    assert "dummy,1.0,1;dummy,1.0,1\n" == Connection.read(pid, "SAMPLE;SAMPLE\n")
  end

  test "reading a sample model" do
    model = Lakeshore350.model()
    opts = [model: model]
    {:ok, pid} = start_supervised({Connection, method: Dummy, method_opts: opts})
    assert "1.0,1.0,1.0\r\n" == Connection.read(pid, "PID? 1\n")
    assert "1\r\n" == Connection.read(pid, "RANGE? 1\n")
  end

  test "reading a joined query" do
    model = Lakeshore350.model()
    opts = [model: model]
    {:ok, pid} = start_supervised({Connection, method: Dummy, method_opts: opts})
    assert "1.0,1.0,1.0;1.0,1.0,1.0\r\n" == Connection.read(pid, "PID? 1;PID? 1\n")
    assert "1.0,1.0,1.0;1\r\n" == Connection.read(pid, "PID? 1;RANGE? 1\n")
  end
end
