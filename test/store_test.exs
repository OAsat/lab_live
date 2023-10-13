defmodule StoreTest do
  alias Labex.Store
  use ExUnit.Case
  doctest Labex.Store

  test "start" do
    {:ok, _pid} = Store.start_link({:var1, :undefined})
    assert :undefined == Store.get(:var1)
    Store.set(:var1, :defined)
    assert :defined == Store.get(:var1)
  end

end
