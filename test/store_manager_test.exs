defmodule StoreManagerTest do
  alias LabLive.StoreManager
  use ExUnit.Case
  doctest StoreManager

  test "register and lookup" do
    {:ok, _pid} = StoreManager.start_agent(:var1)
    assert :undefined = StoreManager.get(:var1)
    assert :ok = StoreManager.set(:var1, 10)
    assert 10 = StoreManager.get(:var1)
  end
end
