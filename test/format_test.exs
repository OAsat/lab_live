defmodule FormatTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Labex.Format

  test "format/2" do
    check all(
            term1 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)]),
            term2 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)])
          ) do
      assert "ab #{term1} cd #{term2} ef" ==
               Labex.Format.format("ab {{term1}} cd {{term2}} ef", term1: term1, term2: term2)
    end
  end
end
