defmodule LabLive.Instrument.PortManagerTest do
  use ExUnit.Case
  alias LabLive.Instrument.PortManager
  doctest PortManager
  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    stub_with(LabLive.Instrument.ImplMock, LabLive.Instrument.FallbackImpl)
    :ok
  end

  describe "port manager starts with application" do
    test "supervisors are started" do
      assert nil != Process.whereis(LabLive.Instrument.PortManager)
      assert nil != Process.whereis(LabLive.Instrument.PortManager.Registry)
      assert nil != Process.whereis(LabLive.Instrument.PortManager.Supervisor)
    end
  end

  describe "port manager APIs" do
    test "start_instrument/4", %{test: test_name} do
      LabLive.Instrument.ImplMock
      |> expect(:init, fn _ -> :resource end)
      |> expect(:terminate, fn :normal, :resource -> :ok end)

      start_supervised({PortManager, name: test_name})
      {:ok, pid} = PortManager.start_instrument(test_name, :inst, :info, type: nil)
      assert :ok = GenServer.stop(pid, :normal)
    end

    test "port resets on second start_instrument/4", %{test: test_name} do
      LabLive.Instrument.ImplMock
      |> expect(:init, 2, fn _ -> :resource end)
      |> expect(:terminate, 2, fn :normal, :resource -> :ok end)

      start_supervised({PortManager, name: test_name})
      {:ok, pid} = PortManager.start_instrument(test_name, :inst, :info, type: nil)
      {:reset, ^pid} = PortManager.start_instrument(test_name, :inst, :info, type: nil)
      assert :ok = GenServer.stop(pid, :normal)
    end

    test "lookup/2, info/2 and pid/2", %{test: test_name} do
      key = :inst
      start_supervised({PortManager, name: test_name})
      {:ok, pid} = PortManager.start_instrument(test_name, key, :info, type: nil)
      assert {^pid, :info} = PortManager.lookup(test_name, key)
      assert :info == PortManager.info(test_name, key)
      assert ^pid = PortManager.pid(test_name, key)
    end

    test "lookup/2 raises error with unknown key", %{test: test_name} do
      start_supervised({PortManager, name: test_name})

      assert_raise(RuntimeError, "Instrument unknown not found.", fn ->
        PortManager.lookup(test_name, :unknown)
      end)
    end

    test "keys_and_pids/1", %{test: test_name} do
      start_supervised({PortManager, name: test_name})
      {:ok, pid1} = PortManager.start_instrument(test_name, :inst1, nil, type: nil)
      {:ok, pid2} = PortManager.start_instrument(test_name, :inst2, nil, type: nil)
      {:ok, pid3} = PortManager.start_instrument(test_name, :inst3, nil, type: nil)
      assert %{inst1: ^pid1, inst2: ^pid2, inst3: ^pid3} = PortManager.keys_and_pids(test_name)
    end
  end
end
