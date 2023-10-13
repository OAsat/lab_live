defmodule InstrumentManagerTest do
  alias Labex.Instrument.DummyInstrument
  alias Labex.InstrumentManager
  use ExUnit.Case
  doctest InstrumentManager

  test "register and lookup" do
    dummy_map = %{"READ:A" => "10"}
    assert {:ok, _pid} = InstrumentManager.start_instrument(:inst1, DummyInstrument, map: dummy_map)
    assert InstrumentManager.read(:inst1, "READ:A") == "10"
    assert InstrumentManager.write(:inst1, "WRITE:A") == :ok
    assert InstrumentManager.read(:inst1, "READ:A") == "10"
  end
end
