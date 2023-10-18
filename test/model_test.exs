defmodule ModelTest do
  use ExUnit.Case
  doctest Labex.Model

  test "def model" do
    defmodule SampleModel do
      use Labex.Model

      def_read(:kelvin, "KRDG? {}", "{}")
      def_write(:setp, "SETP {}, {}")
    end

    assert SampleModel.read(:kelvin) == {"KRDG? {}\n", "{}\n"}
    assert SampleModel.write(:setp) == "SETP {}, {}\n"
  end

  test "termination character" do
    defmodule SampleModel2 do
      use Labex.Model

      @write_termination "\r"
    end

    assert SampleModel2.write_termination() == "\r"
    assert SampleModel2.read_termination() == "\n"
  end
end
