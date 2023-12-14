defmodule LabLive.StorageManagerTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.StorageManager
  alias LabLive.DataInfo

  doctest StorageManager

  test "default supervisor and registry are started" do
    assert nil != Process.whereis(LabLive.StorageManager)
    assert nil != Process.whereis(LabLive.StorageManager.Registry)
    assert nil != Process.whereis(LabLive.StorageManager.Supervisor)
  end

  describe "start_data/4" do
    test "starts a data server", %{test: name} do
      start_supervised({StorageManager, name: name})
      assert {:ok, _pid} = StorageManager.start_data(name, :a, 1, %DataInfo{})
    end

    test "restarts a data server if already started", %{test: name} do
      start_supervised({StorageManager, name: name})
      {:ok, pid} = StorageManager.start_data(name, :a, 1, %DataInfo{})
      assert {:restart, new_pid} = StorageManager.start_data(name, :a, 2, %DataInfo{})
      assert pid != new_pid
    end

    test "updates info on restart", %{test: name} do
      start_supervised({StorageManager, name: name})
      {:ok, _} = StorageManager.start_data(name, :a, 1, %DataInfo{})
      new_info = %DataInfo{label: "new info"}
      assert {:restart, _} = StorageManager.start_data(name, :a, 1, new_info)
      assert new_info == StorageManager.info(name, :a)
    end
  end

  test "pid/2", %{test: name} do
    start_supervised({StorageManager, name: name})
    {:ok, pid} = StorageManager.start_data(name, :a, 1, %DataInfo{})
    assert pid == StorageManager.pid(name, :a)
  end

  test "info/2", %{test: name} do
    start_supervised({StorageManager, name: name})
    info = %DataInfo{label: "label of a"}
    {:ok, _} = StorageManager.start_data(name, :a, 1, info)
    assert info == StorageManager.info(name, :a)
  end

  test "keys_and_pids", %{test: name} do
    start_supervised({StorageManager, name: name})
    {:ok, pid1} = StorageManager.start_data(name, :one, 1, %DataInfo{})
    {:ok, pid2} = StorageManager.start_data(name, :two, 2, %DataInfo{})
    assert %{one: ^pid1, two: ^pid2} = StorageManager.keys_and_pids(name)
  end
end
