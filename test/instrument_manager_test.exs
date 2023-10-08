defmodule InstrumentManagerTest do
  alias Labex.Instrument.DummyInstrument
  alias Labex.InstrumentManager
  use ExUnit.Case
  doctest InstrumentManager

  test "register and lookup" do
    {:ok, _pid} = InstrumentManager.start_link(nil)

    dummy_map = %{"READ:A" => "10"}
    InstrumentManager.start_instrument(:inst1, DummyInstrument, mapping: dummy_map)
    assert InstrumentManager.read(:inst1, "READ:A") == "10"
    assert InstrumentManager.write(:inst1, "WRITE:A") == :ok
  end
end
