defmodule VariableManagerTest do
  alias LabLive.VariableManager
  use ExUnit.Case
  doctest VariableManager

  test "start_getters/1" do
    # {:ok, pid} = start_supervised({VariableManager, name: :test_variable_manager})
    getters = %{
      var1: fn -> 1 end,
      var2: fn -> 2 end
    }

    VariableManager.start_getters(getters)
  end
end
