defmodule ModelTest do
  use ExUnit.Case
  doctest Labex.Instrument.Model

  test "def model" do
    defmodule DummyInstrument do
      def query("KRDG? A", _opts), do "12.34"
    end

    defmodule MyModel do
      use Labex.Instrument.Model

      def_read(:kelvin, "KRDG? ~s", "~f")
    end

    assert MyModel.read(:kelvin, ["A"], DummyInstrument) == [12.34]
  end
end
