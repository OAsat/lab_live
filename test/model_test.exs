defmodule ModelTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest LabLive.Model

  defmodule DummyModel do
    use LabLive.Model

    def_write(:alpha, "query,{{param1}}{{param2}}")
    def_read(:alpha, "query,{{param}}", "answer,{{value:float}}")
  end

  test "termination character" do
    defmodule CheckTerm do
      use LabLive.Model

      @write_termination "\r"
    end

    assert CheckTerm.write_termination() == "\r"
    assert CheckTerm.read_termination() == "\n"
  end

  test "def_write/2" do
    check all(
            param1 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)]),
            param2 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)])
          ) do
      assert "query,#{param1}#{param2}\n" ==
               DummyModel.write(:alpha, param1: param1, param2: param2)

      assert [alpha: "query,{{param1}}{{param2}}"] == DummyModel.write_formats()
    end
  end

  test "def_read/2" do
    check all(
            param <- string(:alphanumeric, min_length: 1),
            value <- float()
          ) do
      {query, parser} = DummyModel.read(:alpha, param: param)
      assert query == "query,#{param}\n"
      assert parser.("answer,#{value}") == [value: value]
      assert [alpha: {"query,{{param}}", "answer,{{value:float}}"}] == DummyModel.read_formats()
    end
  end
end
