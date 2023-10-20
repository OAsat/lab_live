defmodule StoreTest do
  alias LabLive.Store
  use ExUnit.Case
  doctest LabLive.Store

  test "start" do
    {:ok, _pid} = Store.start_link({:var1, :undefined})
    assert :undefined == Store.get(:var1)
    Store.set(:var1, :defined)
    assert :defined == Store.get(:var1)
  end
end
