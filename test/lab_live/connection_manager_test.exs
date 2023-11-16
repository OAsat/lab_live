defmodule LabLive.ConnectionManagerTest do
  use ExUnit.Case
  alias LabLive.ConnectionManager
  alias LabLive.Connection.Method
  doctest ConnectionManager
  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    stub_with(Method.Mock, Method.Fallback)
    :ok
  end

  describe "port manager starts with application" do
    test "supervisors are started" do
      assert nil != Process.whereis(LabLive.ConnectionManager)
      assert nil != Process.whereis(LabLive.ConnectionManager.Registry)
      assert nil != Process.whereis(LabLive.ConnectionManager.Supervisor)
    end
  end

  describe "port manager APIs" do
    test "start_instrument/4", %{test: test_name} do
      Method.Mock
      |> expect(:init, fn _ -> :resource end)
      |> expect(:terminate, fn :normal, :resource -> :ok end)

      start_supervised({ConnectionManager, name: test_name})
      opts = [method: Method.Mock]
      {:ok, pid} = ConnectionManager.start_instrument(test_name, :inst, opts)
      assert :ok = GenServer.stop(pid, :normal)
    end

    test "port resets on second start_instrument/4", %{test: test_name} do
      Method.Mock
      |> expect(:init, 2, fn _ -> :resource end)
      |> expect(:terminate, 2, fn :normal, :resource -> :ok end)

      start_supervised({ConnectionManager, name: test_name})
      opts = [method: Method.Mock]
      {:ok, pid} = ConnectionManager.start_instrument(test_name, :inst, opts)
      {:reset, ^pid} = ConnectionManager.start_instrument(test_name, :inst, opts)
      assert :ok = GenServer.stop(pid, :normal)
    end

    test "lookup/2, info/2 and pid/2", %{test: test_name} do
      start_supervised({ConnectionManager, name: test_name})
      key = :inst
      opts = [method: Method.Fallback]
      {:ok, pid} = ConnectionManager.start_instrument(test_name, key, opts)
      assert {^pid, ^opts} = ConnectionManager.lookup(test_name, key)
      assert opts == ConnectionManager.info(test_name, key)
      assert ^pid = ConnectionManager.pid(test_name, key)
    end

    test "lookup/2 raises error with unknown key", %{test: test_name} do
      start_supervised({ConnectionManager, name: test_name})

      assert_raise(RuntimeError, "Instrument unknown not found.", fn ->
        ConnectionManager.lookup(test_name, :unknown)
      end)
    end

    test "keys_and_pids/1", %{test: test_name} do
      start_supervised({ConnectionManager, name: test_name})
      opts = [method: Method.Fallback]
      {:ok, pid1} = ConnectionManager.start_instrument(test_name, :inst1, opts)
      {:ok, pid2} = ConnectionManager.start_instrument(test_name, :inst2, opts)
      {:ok, pid3} = ConnectionManager.start_instrument(test_name, :inst3, opts)

      assert %{inst1: ^pid1, inst2: ^pid2, inst3: ^pid3} =
               ConnectionManager.keys_and_pids(test_name)
    end
  end
end
