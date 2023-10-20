defmodule VariableManagerTest do
  alias LabLive.VariableManager
  use ExUnit.Case
  doctest VariableManager

  test "register and lookup" do
    {:ok, _pid} = VariableManager.start_agent(:var1)
    assert :undefined = VariableManager.get(:var1)
    assert :ok = VariableManager.set(:var1, 10)
    assert 10 = VariableManager.get(:var1)
  end
end
