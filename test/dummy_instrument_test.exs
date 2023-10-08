defmodule DummyInstrumentTest do
  alias Labex.Instrument.DummyInstrument
  use ExUnit.Case
  doctest DummyInstrument

  test "dummy instrument" do
    mapping = %{
      "READ:A" => "100"
    }
    {:ok, pid} = DummyInstrument.start_link({:dummy, mapping: mapping})
    assert DummyInstrument.read(pid, "READ:A") == "100"
  end
end
