defmodule LabLive.ConnectionTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Connection
  alias LabLive.Connection.Method.Mock
  doctest Connection

  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "method_opts are passed to the method init/1" do
    check all(method_opts <- keyword_of(term())) do
      Mock
      |> expect(:init, fn opts ->
        assert opts == method_opts
        method_opts
      end)
      |> expect(:terminate, fn :normal, opts ->
        assert opts == method_opts
        :ok
      end)

      {:ok, pid} = Connection.start_link(method: Mock, method_opts: method_opts)
      GenServer.stop(pid, :normal)
    end
  end

  test "read/2" do
    check all(message <- string(:ascii)) do
      Mock
      |> expect(:init, fn nil -> :resource end)
      |> expect(:read, fn message, :resource -> message end)
      |> expect(:terminate, fn :normal, :resource -> :ok end)

      {:ok, pid} = Connection.start_link(method: Mock)
      assert ^message = Connection.read(pid, message)
      GenServer.stop(pid, :normal)
    end
  end

  test "write/2" do
    check all(message <- string(:ascii)) do
      Mock
      |> expect(:init, fn nil -> :resource end)
      |> expect(:write, fn writer, :resource ->
        assert writer == message
        :ok
      end)
      |> expect(:terminate, fn :normal, :resource -> :ok end)

      {:ok, pid} = Connection.start_link(method: Mock)
      assert :ok == Connection.write(pid, message)
      GenServer.stop(pid, :normal)
    end
  end

  test "reset/2" do
    Mock
    |> expect(:init, fn "first" -> :resource end)
    |> expect(:init, fn "second" -> :resource end)
    |> expect(:terminate, 2, fn :normal, :resource -> :ok end)

    {:ok, pid} = Connection.start_link(method: Mock, method_opts: "first")
    assert :ok == Connection.reset(pid, method: Mock, method_opts: "second")
    assert :ok == GenServer.stop(pid, :normal)
  end
end
