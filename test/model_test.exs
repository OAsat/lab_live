defmodule ModelTest do
  use ExUnit.Case
  doctest Labex.Instrument.Model

  test "def model" do
    defmodule SampleModel do
      use Labex.Instrument.Model

      def_read(:kelvin, "KRDG? ~s", "~f")
      def_write(:setp, "SETP ~s, ~p")
    end

    assert SampleModel.read(:kelvin) == {"KRDG? ~s\n", "~f\n"}
    assert SampleModel.write(:setp) == "SETP ~s, ~p\n"
  end

  test "termination character" do
    defmodule SampleModel2 do
      use Labex.Instrument.Model

      @write_termination "\r"
    end

    assert SampleModel2.write_termination() == "\r"
    assert SampleModel2.read_termination() == "\n"
  end
end
