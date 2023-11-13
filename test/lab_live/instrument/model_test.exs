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

  test "from map" do
    map = %{
      name: "TestModel",
      query: %{
        param: %{
          input: "SET:{{val1}},{{val2}}"
        },
        param?: %{
          input: "GET:{{val1}},{{val2}}",
          output: "OK:{{val1}},{{val2}}"
        }
      }
    }

    LabLive.Model.define(MyTestModel, map)
    assert {"SET:1.2,3", nil} = MyTestModel.query(:param, val1: 1.2, val2: 3)
    {"GET:4.5,6", parser} = MyTestModel.query(:param?, val1: 4.5, val2: 6)
    assert parser.("OK:4.5,6") == %{val1: 4.5, val2: 6}
  end
end
