defmodule InstrumentManagerTest do
  alias Labex.Instrument.DummyInstrument
  alias Labex.InstrumentManager
  use ExUnit.Case
  doctest InstrumentManager

  test "register and lookup" do
    dummy_map = %{"READ:A" => "10"}

    assert {:ok, _pid} =
             InstrumentManager.start_instrument(:inst1, DummyInstrument, map: dummy_map)

    assert InstrumentManager.read(:inst1, "READ:A") == "10"
    assert InstrumentManager.write(:inst1, "WRITE:A") == :ok
    assert InstrumentManager.read(:inst1, "READ:A") == "10"
  end

  test "read from model" do
    dummy_map = %{"READ:A\n" => "ANSWER:A 12.3unit\n"}

    defmodule MyModel do
      use Labex.Model

      def_read(:a, "READ:{channel}", "ANSWER:{channel:str} {value:float}unit")
    end

    InstrumentManager.start_instrument(:inst2, DummyInstrument, map: dummy_map)

    assert InstrumentManager.read(:inst2, {MyModel, :a, [channel: "A"]}) == [channel: "A", value: 12.3]
  end
end
