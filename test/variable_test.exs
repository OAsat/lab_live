defmodule VariableTest do
  alias LabLive.Variable
  use ExUnit.Case
  doctest Variable

  test "start" do
    {:ok, _pid} = Variable.start_link({:var1, :undefined})
    assert :undefined == Variable.get(:var1)
    Variable.set(:var1, :defined)
    assert :defined == Variable.get(:var1)
  end
end
