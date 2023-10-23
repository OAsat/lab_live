defmodule FormatTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest LabLive.Format

  test "format/2" do
    check all(
            term1 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)]),
            term2 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)])
          ) do
      assert "ab #{term1} cd #{term2} ef" ==
               LabLive.Format.format("ab {{term1}} cd {{term2}} ef", term1: term1, term2: term2)
    end
  end

  test "parse/2" do
    check all(
            val1 <- string(:alphanumeric, min_length: 1),
            val2 <- float(),
            val3 <- integer()
          ) do
      assert %{val1: val1, val2: val2, val3: val3} ==
               LabLive.Format.parse(
                 "s #{val1},#{val2},#{val3} e",
                 "s {{val1:str}},{{val2:float}},{{val3:int}} e"
               )
    end
  end
end
