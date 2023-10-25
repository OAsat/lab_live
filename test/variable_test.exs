defmodule VariableTest do
  alias LabLive.Variable
  use ExUnit.Case
  doctest Variable

  test "start_getters/1" do
    # {:ok, pid} = start_supervised({Variable, name: :test_variable_manager})
    getters = %{
      var1: fn -> 1 end,
      var2: fn -> 2 end
    }

    Variable.start_getters(getters)
  end
end
