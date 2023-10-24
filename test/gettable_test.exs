defmodule GettableTest do
  alias LabLive.Gettable
  use ExUnit.Case
  use ExUnitProperties

  doctest Gettable

  test "getter/0" do
    check all(func_return <- term()) do
      update_func = fn -> func_return end
      {:ok, pid} = GenServer.start_link(Gettable, update_func)
      assert func_return == Gettable.get(pid)
      assert func_return == Gettable.latest(pid)
    end
  end
end
