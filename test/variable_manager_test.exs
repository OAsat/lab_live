defmodule VariableManagerTest do
  alias LabLive.VariableManager
  use ExUnit.Case
  doctest VariableManager

  test "register and lookup" do
    variables = [
      :var1,
      {:var2, init: 100}
    ]

    VariableManager.start_variables(variables)
    assert :empty = VariableManager.get(:var1)
    assert 100 = VariableManager.get(:var2)
  end
end
