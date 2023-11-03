defmodule LabLive.Instrument.ModelTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest LabLive.Instrument.Model

  test "termination character" do
    defmodule CheckTerm do
      use LabLive.Instrument.Model

      def write_termination() do
        "\r"
      end
    end

    assert CheckTerm.write_termination() == "\r"
    assert CheckTerm.read_termination() == "\n"
  end
end
