defmodule MeasurementTest do
  use ExUnit.Case
  doctest Labex.Measurement

  test "def measurement" do
    defmodule Measurement do
      use Labex.Measurement

      def_inst(:inst1, MyModel, Dummy, param1: 1, param2: 2)
      def_inst(:inst2, MyModel, Dummy, nil)
    end

    assert Measurement.instruments() == %{
             inst1: {MyModel, Dummy, param1: 1, param2: 2},
             inst2: {MyModel, Dummy, nil}
           }
  end

  test "start instruments" do
    defmodule StartInstruments do
      use Labex.Measurement

      def_inst(:inst3, MyModel, Labex.Instrument.DummyInstrument, map: %{})
    end

    StartInstruments.start_instruments()
  end

  test "read" do
    dummy_map = %{"READ\n" => "hello\n"}

    defmodule MyModel do
      use Labex.Model

      def_read(:a, "READ", "{answer:str}")
    end

    defmodule Measurement3 do
      use Labex.Measurement

      def_inst(:inst4, MyModel, Labex.Instrument.DummyInstrument, map: dummy_map)
    end

    Measurement3.start_instruments()
    assert Measurement3.read(:inst4, :a, []) == [answer: "hello"]
  end
end
