defmodule LabexTest do
  alias InstrumentTest.DummyInstrument
  use ExUnit.Case
  doctest Labex

  test "def measurement" do
    defmodule DummyInstrument do
      def query("KRDG? A", _opts), do: "12.34"
    end

    defmodule MyModel do
      use Labex.Instrument.Model

      def_read(:kelvin, "KRDG? ~s", "~f")
    end

    defmodule Measurement do
      use Labex

      instrument(:inst1, MyModel, DummyInstrument)
      instrument(:inst2, MyModel, DummyInstrument)

      readable(:t1, :inst1, :kelvin)
      readable(:t2, :inst2, :kelvin)
    end
  end
end
