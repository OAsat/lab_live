defmodule LabLive.InstrumentTest do
  use ExUnit.Case
  alias LabLive.Instrument
  alias LabLive.Model
  alias LabLive.Connection.Method
  doctest Instrument

  import Mox
  setup :set_mox_from_context
  setup :verify_on_exit!

  test "loading instruments_sample.toml" do
    toml_file = "test/support/instruments_sample.toml"
    specs = Instrument.load_toml_file(toml_file)
    ls_model = Model.from_file("test/support/models/lakeshore350.model.toml")
    mercury_model = Model.from_file("test/support/models/oxford_mercury_itc.model.toml")
    assert specs.lakeshore.model == ls_model
    assert specs.lakeshore_2.model == ls_model
    assert specs.mercury.model == mercury_model
  end

  describe "start_instruments/3" do
    test "dummy instrument starts", %{test: test_name} do
      start_supervised({LabLive.ConnectionManager, name: test_name})

      instruments = %{inst1: %{dummy: %{}}}

      [inst1: {:ok, _pid}] =
        Instrument.start_instruments(test_name, instruments, inst1: :dummy)
    end

    test "tcp instrument starts", %{test: test_name} do
      start_supervised({LabLive.ConnectionManager, name: test_name})
      instruments = %{inst1: %{tcp: %{address: [0, 0, 0, 0], port: 1234}}}

      [inst1: {:ok, _pid}] =
        Instrument.start_instruments(test_name, instruments, inst1: :tcp)
    end

    test "mock instrument starts", %{test: test_name} do
      start_supervised({LabLive.ConnectionManager, name: test_name})

      Method.Mock
      |> expect(:init, fn %{} -> :resource end)
      |> stub(:terminate, fn _reason, _resource -> :ok end)

      instruments = %{inst1: %{Method.Mock => %{}}}

      [inst1: {:ok, _pid}] =
        Instrument.start_instruments(test_name, instruments, inst1: Method.Mock)
    end
  end

  test "read/3", %{test: test_name} do
    start_supervised({LabLive.ConnectionManager, name: test_name})

    Method.Mock
    |> expect(:init, fn %{} -> :resource end)
    |> expect(:read, fn "hello", :resource -> "goodbye" end)
    |> expect(:read, fn "goodbye", :resource -> "hello" end)
    |> stub(:terminate, fn _reason, _resource -> :ok end)

    instruments = %{inst1: %{Method.Mock => %{}}}

    [inst1: {:ok, pid}] =
      Instrument.start_instruments(test_name, instruments, inst1: Method.Mock)

    assert "goodbye" == Instrument.read(test_name, :inst1, "hello")
    assert "hello" == Instrument.read(test_name, :inst1, "goodbye")
    assert :ok == GenServer.stop(pid, :normal)
  end

  test "write/3", %{test: test_name} do
    start_supervised({LabLive.ConnectionManager, name: test_name})

    Method.Mock
    |> expect(:init, fn %{} -> :resource end)
    |> expect(:write, fn "hello", :resource -> :ok end)
    |> stub(:terminate, fn _reason, _resource -> :ok end)

    instruments = %{inst1: %{Method.Mock => %{}}}

    [inst1: {:ok, pid}] =
      Instrument.start_instruments(test_name, instruments, inst1: Method.Mock)

    assert :ok == Instrument.write(test_name, :inst1, "hello")
    assert :ok == GenServer.stop(pid, :normal)
  end

  test "query/2", %{test: test_name} do
    start_supervised({LabLive.ConnectionManager, name: test_name})

    Method.Mock
    |> expect(:init, fn %{} -> :resource end)
    |> expect(:read, fn "PID? 1\n", :resource -> "100,50,0\r\n" end)
    |> expect(:write, fn "PID 1,50,25,0\n", :resource -> :ok end)
    |> expect(:read, fn "KRDG? 2\n", :resource -> "12.34\r\n" end)
    |> stub(:terminate, fn _reason, _resource -> :ok end)

    model = Lakeshore350.model()

    instruments = %{lakeshore: %{:model => model, Method.Mock => %{}}}

    [lakeshore: {:ok, pid}] =
      Instrument.start_instruments(test_name, instruments, lakeshore: Method.Mock)

    assert %{p: 100, i: 50, d: 0} == Instrument.query(test_name, :lakeshore, :pid?, channel: 1)
    assert :ok == Instrument.query(test_name, :lakeshore, :pid, channel: 1, p: 50, i: 25, d: 0)
    assert %{kelvin: 12.34} == Instrument.query(test_name, :lakeshore, :temp?, channel: 2)
    assert :ok == GenServer.stop(pid, :normal)
  end
end
