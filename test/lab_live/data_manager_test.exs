defmodule LabLive.DataManagerTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.DataManager
  alias LabLive.DataInfo

  doctest DataManager

  test "default supervisor and registry are started" do
    assert nil != Process.whereis(LabLive.DataManager)
    assert nil != Process.whereis(LabLive.DataManager.Registry)
    assert nil != Process.whereis(LabLive.DataManager.Supervisor)
  end

  describe "start_data/4" do
    test "starts a data server", %{test: name} do
      start_supervised({DataManager, name: name})
      assert {:ok, _pid} = DataManager.start_data(name, :a, 1, %DataInfo{})
    end

    test "restarts a data server if already started", %{test: name} do
      start_supervised({DataManager, name: name})
      {:ok, pid} = DataManager.start_data(name, :a, 1, %DataInfo{})
      assert {:restart, new_pid} = DataManager.start_data(name, :a, 2, %DataInfo{})
      assert pid != new_pid
    end

    test "updates info on restart", %{test: name} do
      start_supervised({DataManager, name: name})
      {:ok, _} = DataManager.start_data(name, :a, 1, %DataInfo{})
      new_info = %DataInfo{label: "new info"}
      assert {:restart, _} = DataManager.start_data(name, :a, 1, new_info)
      assert new_info == DataManager.info(name, :a)
    end
  end

  test "pid/2", %{test: name} do
    start_supervised({DataManager, name: name})
    {:ok, pid} = DataManager.start_data(name, :a, 1, %DataInfo{})
    assert pid == DataManager.pid(name, :a)
  end

  test "info/2", %{test: name} do
    start_supervised({DataManager, name: name})
    info = %DataInfo{label: "label of a"}
    {:ok, _} = DataManager.start_data(name, :a, 1, info)
    assert info == DataManager.info(name, :a)
  end

  test "keys_and_pids", %{test: name} do
    start_supervised({DataManager, name: name})
    {:ok, pid1} = DataManager.start_data(name, :one, 1, %DataInfo{})
    {:ok, pid2} = DataManager.start_data(name, :two, 2, %DataInfo{})
    assert %{one: ^pid1, two: ^pid2} = DataManager.keys_and_pids(name)
  end
end
