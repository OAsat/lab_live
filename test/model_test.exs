defmodule ModelTest do
  use ExUnit.Case
  doctest Labex.Instrument.Model

  test "def model" do
    defmodule DummyInstrument do
      alias Labex.Instrument.Impl
      @behaviour Impl

      def read("KRDG? A", :kelvin), do: "12.34"
      def read("KRDG? A", :expect_error), do: "12.34, 5.6"
      def write("SETP A, 123.4", :setp), do: :ok
    end

    defmodule MyModel do
      use Labex.Instrument.Model

      def_read(:kelvin, "KRDG? ~s", "~f")
      def_read(:expect_error, "KRDG? ~s", "~f")
      def_write(:setp, "SETP ~s, ~p")
    end

    assert MyModel.read(:kelvin, ["A"], DummyInstrument) == [12.34]
    assert MyModel.write(:setp, ["A", 123.4], DummyInstrument) == :ok

    assert_raise(
      RuntimeError,
      "'12.34, 5.6' doesn't match to the expected format '~f'.",
      fn -> MyModel.read(:expect_error, ["A"], DummyInstrument) end
    )
  end
end
