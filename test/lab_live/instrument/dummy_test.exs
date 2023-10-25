defmodule LabLive.Instrument.DummyTest do
  alias LabLive.Instrument.Dummy
  use ExUnit.Case
  doctest Dummy

  test "dummy instrument" do
    map = %{
      "READ:A" => "100"
    }

    {:ok, pid} = Dummy.start_link({:dummy, map: map})
    assert Dummy.read(pid, "READ:A") == "100"
  end
end
