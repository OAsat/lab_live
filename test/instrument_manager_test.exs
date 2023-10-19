defmodule InstrumentManagerTest do
  alias Labex.Instrument.DummyInstrument
  alias Labex.InstrumentManager, as: Im
  use ExUnit.Case
  doctest Im

  test "register and lookup" do
    defmodule DummyModel do
      use Labex.Model

      def_read(:a, "READ:{channel}", "ANSWER:{channel:str} {value:float}K")
      # def_write(:a, "WRITE:{channel},{value}", "SUCCESS:{channel:str} {value:float}K")
    end

    dummy_map = %{"READ:A\n" => "ANSWER:A 12.3K\n"}

    assert {:ok, _pid} = Im.start_instrument(:inst1, DummyInstrument, map: dummy_map)

    assert Im.read(:inst1, "READ:A\n") == "ANSWER:A 12.3K\n"
    assert Im.write(:inst1, "WRITE:A\n") == :ok

    assert {:ok, _pid} =
             Im.start_instrument(:inst2, DummyModel, DummyInstrument,
               map: dummy_map
             )

    assert Im.read(:inst2, "READ:A\n") == "ANSWER:A 12.3K\n"
    assert Im.write(:inst2, "WRITE:A\n") == :ok
    assert Im.read(:inst2, :a, channel: "A") == [channel: "A", value: 12.3]
    assert Im.write(:inst2, "WRITE:A\n") == :ok

    inst_list = [
      {:inst3, DummyInstrument, map: dummy_map},
      {:inst4, DummyModel, DummyInstrument, map: dummy_map}
    ]
    assert [{:ok, _}, {:ok, _}] = Im.start_instruments(inst_list)
  end

  test "read from model" do
    # dummy_map = %{"READ:A\n" => "ANSWER:A 12.3unit\n"}

    # defmodule MyModel do
    #   use Labex.Model

    #   def_read(:a, "READ:{channel}", "ANSWER:{channel:str} {value:float}unit")
    # end

    # InstrumentManager.start_instrument(:inst2, MyModel, DummyInstrument, map: dummy_map)

    # assert InstrumentManager.read(:inst2, {MyModel, :a, [channel: "A"]}) == [
    #          channel: "A",
    #          value: 12.3
    #        ]

    # assert InstrumentManager.read(:inst2, :a, channel: "A") == [
    #          channel: "A",
    #          value: 12.3
    #        ]
  end
end
