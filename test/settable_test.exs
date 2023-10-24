defmodule SettableTest do
  alias LabLive.Settable
  use ExUnit.Case
  use ExUnitProperties

  doctest Settable

  test "setter/1" do
    check all(list <- list_of(term())) do
      setter = fn v -> v end
      {:ok, pid} = GenServer.start_link(Settable, setter)

      for value <- list do
        assert value == Settable.set(pid, value)
        assert value == Settable.latest(pid)
      end
    end
  end
end
