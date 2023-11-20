defmodule LabLive.ConnectionManagerTest do
  use ExUnit.Case
  alias LabLive.ConnectionManager
  alias LabLive.Connection.Method
  alias Method.Mock
  alias Method.Fallback
  doctest ConnectionManager
  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    stub_with(Mock, Fallback)
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
      info = :info
      {:ok, pid} = ConnectionManager.start_instrument(test_name, :inst, info, opts)
      assert :ok = GenServer.stop(pid, :normal)
    end

    test "connection opts reset on second start_instrument/4", %{test: test_name} do
      Method.Mock
      |> expect(:init, fn "first" -> :resource end)
      |> expect(:init, fn "second" -> :resource end)
      |> expect(:terminate, 2, fn :normal, :resource -> :ok end)

      start_supervised({ConnectionManager, name: test_name})

      {:ok, pid} =
        ConnectionManager.start_instrument(test_name, :inst, "info1",
          method: Method.Mock,
          method_opts: "first"
        )

      {:reset, ^pid} =
        ConnectionManager.start_instrument(test_name, :inst, "info2",
          method: Method.Mock,
          method_opts: "second"
        )

      # TODO fix: The info is not updated. The registry value can only be updated from the Connection process.
      assert "info1" == ConnectionManager.info(test_name, :inst)
      assert :ok = GenServer.stop(pid, :normal)
    end

    test "lookup/2, info/2 and pid/2", %{test: test_name} do
      start_supervised({ConnectionManager, name: test_name})
      key = :inst
      opts = [method: Method.Fallback]
      info = :info
      {:ok, pid} = ConnectionManager.start_instrument(test_name, key, info, opts)
      assert {^pid, ^info} = ConnectionManager.lookup(test_name, key)
      assert info == ConnectionManager.info(test_name, key)
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
      info = :info
      {:ok, pid1} = ConnectionManager.start_instrument(test_name, :inst1, info, opts)
      {:ok, pid2} = ConnectionManager.start_instrument(test_name, :inst2, info, opts)
      {:ok, pid3} = ConnectionManager.start_instrument(test_name, :inst3, info, opts)

      assert %{inst1: ^pid1, inst2: ^pid2, inst3: ^pid3} =
               ConnectionManager.keys_and_pids(test_name)
    end
  end
end
