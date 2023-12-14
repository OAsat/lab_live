defmodule LabLive.StorageTest do
  alias LabLive.Storage
  alias LabLive.Data.Iterator
  alias LabLive.Data.Loop
  use ExUnit.Case
  use ExUnitProperties
  doctest Storage

  test "get/1" do
    check all(init <- term()) do
      {:ok, pid} = Storage.start_link(init: init)
      assert init == Storage.get(pid)
    end
  end

  describe "value/1" do
    test "when the data is a scalar" do
      check all(init <- term()) do
        {:ok, pid} = Storage.start_link(init: init)
        assert init == Storage.value(pid)
      end
    end

    test "when the data is an iterator" do
      iter = Iterator.new([1, 2, 3])
      {:ok, pid} = Storage.start_link(init: iter)
      assert :not_started == Storage.value(pid)
    end
  end

  describe "update/2" do
    test "when the data is a scalar" do
      {:ok, pid} = Storage.start_link(init: 10)
      :ok = Storage.update(20, pid)
      assert 20 == Storage.get(pid)
    end

    test "when the data is an iterator" do
      iter = Iterator.new([1, 2, 3])
      {:ok, pid} = Storage.start_link(init: iter)
      :ok = Storage.update(pid)
      assert 1 == Storage.value(pid)
    end
  end

  test "override/2" do
    {:ok, pid} = Storage.start_link(init: 10)
    :ok = Storage.override(20, pid)
    assert 20 == Storage.get(pid)
  end
end
