defmodule LabLive.DataTest do
  alias LabLive.Data
  alias LabLive.Data.Loop
  alias LabLive.StorageManager
  alias LabLive.DataInfo
  use ExUnit.Case
  use ExUnitProperties

  doctest Data

  describe "start_data/2" do
    test "starts multiple data servers with keyword specs", %{test: name} do
      start_supervised({StorageManager, name: name})

      many_data = [
        a: [init: 1, info: %DataInfo{}],
        b: [init: 2, info: %DataInfo{}]
      ]

      assert [a: {:ok, _}, b: {:ok, _}] = Data.start_data(name, many_data)
    end

    test "starts multiple data servers with map specs", %{test: name} do
      start_supervised({StorageManager, name: name})

      many_data = %{
        a: [init: 1, info: %DataInfo{}],
        b: [init: 2, info: %DataInfo{}]
      }

      assert [a: {:ok, _}, b: {:ok, _}] = Data.start_data(name, many_data)
    end
  end

  test "get/2", %{test: name} do
    start_supervised({StorageManager, name: name})

    check all(term <- term()) do
      Data.start_data(name, data: [init: term, info: %DataInfo{}])
      assert term == Data.get(name, :data)
    end
  end

  describe "value/2" do
    test "when the value is a loop", %{test: name} do
      start_supervised({StorageManager, name: name})

      check all(term <- term()) do
        list = [term]
        Data.start_data(name, data: [init: Loop.new(list), info: %DataInfo{}])
        assert term == Data.value(name, :data)
      end
    end
  end
end
