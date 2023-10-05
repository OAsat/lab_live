defmodule ModelTest do
  use ExUnit.Case
  doctest Labex.Instrument.Model

  test "def model" do
    defmodule DummyInstrument do
      alias Labex.Instrument.Impl
      @behaviour Impl

      def read("KRDG? A", _opts), do: "12.34"
      def write("SETP A, 123.4", _opts), do: :ok
    end

    defmodule MyModel do
      use Labex.Instrument.Model

      def_read(:kelvin, "KRDG? ~s", "~f")
      def_write(:setp, "SETP ~s, ~p")
    end

    assert MyModel.read(:kelvin, ["A"], DummyInstrument) == [12.34]
    assert MyModel.write(:setp, ["A", 123.4], DummyInstrument) == :ok
  end
end
