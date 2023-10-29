defmodule LabLive.ModelTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest LabLive.Model

  test "termination character" do
    defmodule CheckTerm do
      use LabLive.Model

      def write_termination() do
        "\r"
      end
    end

    assert CheckTerm.write_termination() == "\r"
    assert CheckTerm.read_termination() == "\n"
  end
end
