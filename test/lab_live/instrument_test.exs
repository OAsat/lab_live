defmodule LabLive.InstrumentTest do
  alias LabLive.Instrument.Dummy
  alias LabLive.Instrument, as: Im
  use ExUnit.Case
  doctest Im

  test "register and lookup" do
    defmodule DummyModel do
      use LabLive.Model

      def_read(:a, "READ:{{channel}}", "ANSWER:{{channel:str}} {{value:float}}K")
      def_write(:a, "WRITE:{{channel}}")
      def_read(:b, "READ:B", "ANSWER:B {{value:float}}K")
    end

    dummy_map = %{
      "READ:A\n" => "ANSWER:A 12.3K\n",
      "WRITE:A\n" => :ok,
      "READ:B\n" => "ANSWER:B 45.6K\n"
    }

    inst_list = %{
      inst1: {Dummy, map: dummy_map},
      inst2: {DummyModel, Dummy, map: dummy_map}
    }

    assert %{inst1: {:ok, _}, inst2: {:ok, _}} = Im.start_instruments(inst_list)

    assert Im.read(:inst1, "READ:A\n") == "ANSWER:A 12.3K\n"
    assert Im.write(:inst1, "WRITE:A\n") == :ok
    assert Im.read(:inst1, {DummyModel, :a, channel: "A"}) == %{channel: "A", value: 12.3}
    assert Im.read(:inst1, {DummyModel, :b, []}) == %{value: 45.6}
    assert Im.write(:inst1, {DummyModel, :a, channel: "A"}) == :ok

    assert Im.read(:inst2, :a, channel: "A") == %{channel: "A", value: 12.3}
    assert Im.read(:inst2, :b) == %{value: 45.6}
    assert Im.write(:inst2, :a, channel: "A") == :ok
  end
end
