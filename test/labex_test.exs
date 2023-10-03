defmodule LabexTest do
  use ExUnit.Case
  doctest Labex

  test "def instruments" do
    defmodule LabexTest.InstrA do
      use Labex.Instrument
    end

    defmodule LabexTest.InstrB do
      use Labex.Instrument
    end

    defmodule LabexTest.Measurement do
      use Labex

      instrument(:instr_a, LabexTest.InstrA, {})
      instrument(:instr_b, LabexTest.InstrB, {})
    end

    assert Labex.instruments() == [:instr_a, :instr_b]
  end
end
