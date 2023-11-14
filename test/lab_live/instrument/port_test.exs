defmodule LabLive.Instrument.PortTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest LabLive.Instrument.Port

  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "read/2" do
    check all(message <- string(:ascii)) do
      LabLive.Instrument.ImplMock
      |> expect(:init, fn [type: nil] -> :resource end)
      |> expect(:read, fn message, :resource -> {message, :after_read} end)
      |> expect(:after_reply, fn :after_read, :resource -> :ok end)
      |> expect(:write, 0, fn _, :resource -> :ok end)
      |> expect(:terminate, fn :normal, :resource -> :ok end)

      {:ok, pid} = LabLive.Instrument.Port.start_link(type: nil)
      assert ^message = LabLive.Instrument.Port.read(pid, message)
      GenServer.stop(pid, :normal)
    end
  end

  test "write/2" do
    check all(message <- string(:ascii)) do
      LabLive.Instrument.ImplMock
      |> expect(:init, fn [type: nil] -> :resource end)
      |> expect(:read, 0, fn _, :resource -> {nil, :after_read} end)
      |> expect(:write, fn writer, :resource ->
        assert writer == message
        :ok
      end)
      |> expect(:after_reply, 0, fn :after_read, :resource -> :ok end)
      |> expect(:terminate, fn :normal, :resource -> :ok end)

      {:ok, pid} = LabLive.Instrument.Port.start_link(type: nil)
      assert :ok == LabLive.Instrument.Port.write(pid, message)
      GenServer.stop(pid, :normal)
    end
  end

  test "reset/2" do
    LabLive.Instrument.ImplMock
    |> expect(:init, 2, fn [type: nil] -> :resource end)
    |> expect(:terminate, 2, fn :normal, :resource -> :ok end)

    {:ok, pid} = LabLive.Instrument.Port.start_link(type: nil)
    assert :ok == LabLive.Instrument.Port.reset(pid, type: nil)
    assert :ok == GenServer.stop(pid, :normal)
  end
end
