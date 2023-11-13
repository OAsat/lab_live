defmodule LabLive.Model.FormatTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Model.Format

  doctest Format

  test "format/2" do
    check all(
            term1 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)]),
            term2 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)])
          ) do
      assert "ab #{term1} cd #{term2} ef" ==
               Format.format("ab {{term1}} cd {{term2}} ef", term1: term1, term2: term2)
    end
  end

  test "parse/2" do
    check all(
            val1 <- string(:alphanumeric, min_length: 1),
            val2 <- float(),
            val3 <- integer()
          ) do
      assert [val3: val3, val2: val2, val1: val1] ==
               Format.parse(
                 "s #{val3},#{val2},#{val1} e",
                 "s {{val3:int}},{{val2:float}},{{val1:str}} e"
               )
    end
  end
end
