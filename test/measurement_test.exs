defmodule MeasurementTest do
  use ExUnit.Case
  doctest Labex.Measurement

  test "def measurement" do
    defmodule Measurement do
      use Labex.Measurement

      instrument(:inst1, MyModel, Dummy, nil)
      instrument(:inst2, MyModel, Dummy, nil)

      # readable(:t1, :inst1, :kelvin)
      # readable(:t2, :inst2, :kelvin)
    end

    assert Measurement.instruments() == %{
             inst1: {MyModel, {Dummy, {:inst1, nil}}},
             inst2: {MyModel, {Dummy, {:inst2, nil}}}
           }
  end
end
