defmodule MeasurementTest do
  use ExUnit.Case
  doctest Labex.Measurement

  test "def measurement" do
    defmodule Measurement do
      use Labex.Measurement

      def_inst(:inst1, MyModel, Dummy, param1: 1, param2: 2)
      def_inst(:inst2, MyModel, Dummy, nil)

      # readable(:t1, :inst1, :kelvin)
      # readable(:t2, :inst2, :kelvin)
    end

    assert Measurement.instruments() == [
             {:inst2, MyModel, Dummy, nil},
             {:inst1, MyModel, Dummy, param1: 1, param2: 2}
           ]
  end


  test "start instruments" do
    defmodule StartInstruments do
      use Labex.Measurement

      def_inst(:inst3, MyModel, Labex.Instrument.DummyInstrument, map: %{})
    end

    StartInstruments.start_instruments()
  end
end
