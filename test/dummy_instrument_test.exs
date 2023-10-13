defmodule DummyInstrumentTest do
  alias Labex.Instrument.DummyInstrument
  use ExUnit.Case
  doctest DummyInstrument

  test "dummy instrument" do
    map = %{
      "READ:A" => "100"
    }

    {:ok, pid} = DummyInstrument.start_link({:dummy, map: map})
    assert DummyInstrument.read(pid, "READ:A") == "100"
  end
end
