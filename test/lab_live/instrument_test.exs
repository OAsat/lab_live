defmodule LabLive.InstrumentTest do
  use ExUnit.Case
  alias LabLive.Instrument
  alias LabLive.Model
  alias LabLive.Connection.Method
  doctest Instrument

  import Mox
  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    model = %Model{
      character: %{input_term: "\n", output_term: "\r\n", joiner: ";"},
      query: %{
        a: %{input: "input A"},
        b: %{input: "input B", output: "output B"},
        c: %{input: "input C {{param1}}"},
        d: %{input: "input D {{param1}}", output: "output D {{answer1}}"}
      }
    }

    [model: model]
  end

  test "loading instruments_sample.toml" do
    toml_file = "test/support/instruments_sample.toml"
    specs = Instrument.load_toml_file(toml_file)
    ls_model = Model.from_file("test/support/models/lakeshore350.model.toml")
    mercury_model = Model.from_file("test/support/models/oxford_mercury_itc.model.toml")
    assert specs.lakeshore.model == ls_model
    assert specs.lakeshore_2.model == ls_model
    assert specs.mercury.model == mercury_model
  end

  test "with default manager", %{model: model} do
    Method.Mock
    |> expect(:init, fn %{} -> :resource end)
    |> expect(:write, 2, fn "input A\n", :resource -> :ok end)
    |> expect(:read, 2, fn "input B\n", :resource -> "output B\r\n" end)
    |> expect(:write, 2, fn "input C testC\n", :resource -> :ok end)
    |> expect(:read, 2, fn "input D testD\n", :resource -> "output D answer" end)
    |> stub(:terminate, fn _reason, _resource -> :ok end)

    instruments = %{test_default_manager: %{:model => model, Method.Mock => %{}}}

    [test_default_manager: {:ok, pid}] =
      Instrument.start_instruments(instruments, test_default_manager: Method.Mock)

    assert :ok == Instrument.query(:test_default_manager, :a)
    assert :ok == Instrument.write(:test_default_manager, :a)
    assert %{} == Instrument.query(:test_default_manager, :b)
    assert %{} == Instrument.read(:test_default_manager, :b)
    assert :ok == Instrument.query(:test_default_manager, :c, param1: "testC")
    assert :ok == Instrument.write(:test_default_manager, :c, param1: "testC")
    assert %{answer1: "answer"} == Instrument.query(:test_default_manager, :d, param1: "testD")
    assert %{answer1: "answer"} == Instrument.read(:test_default_manager, :d, param1: "testD")
    assert :ok == GenServer.stop(pid, :normal)
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

  test "read_text/3", %{test: test_name} do
    start_supervised({LabLive.ConnectionManager, name: test_name})

    Method.Mock
    |> expect(:init, fn %{} -> :resource end)
    |> expect(:read, fn "hello", :resource -> "goodbye" end)
    |> expect(:read, fn "goodbye", :resource -> "hello" end)
    |> stub(:terminate, fn _reason, _resource -> :ok end)

    instruments = %{inst1: %{Method.Mock => %{}}}

    [inst1: {:ok, pid}] =
      Instrument.start_instruments(test_name, instruments, inst1: Method.Mock)

    assert "goodbye" == Instrument.read_text(test_name, :inst1, "hello")
    assert "hello" == Instrument.read_text(test_name, :inst1, "goodbye")
    assert :ok == GenServer.stop(pid, :normal)
  end

  test "write_text/3", %{test: test_name} do
    start_supervised({LabLive.ConnectionManager, name: test_name})

    Method.Mock
    |> expect(:init, fn %{} -> :resource end)
    |> expect(:write, fn "hello", :resource -> :ok end)
    |> stub(:terminate, fn _reason, _resource -> :ok end)

    instruments = %{inst1: %{Method.Mock => %{}}}

    [inst1: {:ok, pid}] =
      Instrument.start_instruments(test_name, instruments, inst1: Method.Mock)

    assert :ok == Instrument.write_text(test_name, :inst1, "hello")
    assert :ok == GenServer.stop(pid, :normal)
  end

  describe "using model" do
    test "query/4", %{test: test_name, model: model} do
      Method.Mock
      |> expect(:init, fn %{} -> :resource end)
      |> expect(:write, fn "input A\n", :resource -> :ok end)
      |> expect(:read, fn "input B\n", :resource -> "output B\r\n" end)
      |> expect(:write, fn "input C testC\n", :resource -> :ok end)
      |> expect(:read, fn "input D testD\n", :resource -> "output D answer" end)
      |> stub(:terminate, fn _reason, _resource -> :ok end)

      instruments = %{inst: %{:model => model, Method.Mock => %{}}}
      start_supervised({LabLive.ConnectionManager, name: test_name})

      [inst: {:ok, pid}] =
        Instrument.start_instruments(test_name, instruments, inst: Method.Mock)

      assert :ok == Instrument.query(test_name, :inst, :a)
      assert %{} == Instrument.query(test_name, :inst, :b)
      assert :ok == Instrument.query(test_name, :inst, :c, param1: "testC")
      assert %{answer1: "answer"} == Instrument.query(test_name, :inst, :d, param1: "testD")
      assert :ok == GenServer.stop(pid, :normal)
    end

    test "read/4", %{test: test_name, model: model} do
      Method.Mock
      |> expect(:init, fn %{} -> :resource end)
      |> expect(:read, fn "input B\n", :resource -> "output B\r\n" end)
      |> expect(:read, fn "input D test\n", :resource -> "output D answer" end)
      |> stub(:terminate, fn :normal, _resource -> :ok end)

      instruments = %{inst: %{:model => model, Method.Mock => %{}}}
      start_supervised({LabLive.ConnectionManager, name: test_name})

      [inst: {:ok, pid}] =
        Instrument.start_instruments(test_name, instruments, inst: Method.Mock)

      assert %{} == Instrument.read(test_name, :inst, :b)
      assert %{answer1: "answer"} == Instrument.read(test_name, :inst, :d, param1: "test")
      assert :ok == GenServer.stop(pid, :normal)
    end

    test "read_joined/3", %{test: test_name, model: model} do
      Method.Mock
      |> expect(:init, fn %{} -> :resource end)
      |> expect(:read, fn "input B;input D test\n", :resource ->
        "output B;output D answer\r\n"
      end)
      |> stub(:terminate, fn :normal, _resource -> :ok end)

      instruments = %{inst: %{:model => model, Method.Mock => %{}}}
      start_supervised({LabLive.ConnectionManager, name: test_name})

      [inst: {:ok, pid}] =
        Instrument.start_instruments(test_name, instruments, inst: Method.Mock)

      assert [b: %{}, d: %{answer1: "answer"}] ==
               Instrument.read_joined(test_name, :inst, b: [], d: [param1: "test"])

      assert :ok == GenServer.stop(pid, :normal)
    end

    test "write/4", %{test: test_name, model: model} do
      Method.Mock
      |> expect(:init, fn %{} -> :resource end)
      |> expect(:write, fn "input A\n", :resource -> :ok end)
      |> expect(:write, fn "input C test\n", :resource -> :ok end)
      |> stub(:terminate, fn :normal, _resource -> :ok end)

      instruments = %{inst: %{:model => model, Method.Mock => %{}}}
      start_supervised({LabLive.ConnectionManager, name: test_name})

      [inst: {:ok, pid}] =
        Instrument.start_instruments(test_name, instruments, inst: Method.Mock)

      assert :ok == Instrument.write(test_name, :inst, :a)
      assert :ok == Instrument.write(test_name, :inst, :c, param1: "test")
      assert :ok == GenServer.stop(pid, :normal)
    end

    test "write_joined/3", %{test: test_name, model: model} do
      Method.Mock
      |> expect(:init, fn %{} -> :resource end)
      |> expect(:write, fn "input A;input C write_joined test\n", :resource -> :ok end)
      |> stub(:terminate, fn :normal, _resource -> :ok end)

      instruments = %{inst: %{:model => model, Method.Mock => %{}}}
      start_supervised({LabLive.ConnectionManager, name: test_name})

      [inst: {:ok, pid}] =
        Instrument.start_instruments(test_name, instruments, inst: Method.Mock)

      assert :ok ==
               Instrument.write_joined(test_name, :inst, a: [], c: [param1: "write_joined test"])

      assert :ok == GenServer.stop(pid, :normal)
    end
  end
end
