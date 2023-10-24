defmodule SetterTest do
  alias LabLive.Setter
  use ExUnit.Case
  use ExUnitProperties

  doctest Setter

  test "setter/1" do
    check all(list <- list_of(term())) do
      setter = fn v -> v end
      {:ok, pid} = GenServer.start_link(Setter, setter)

      for value <- list do
        assert value == Setter.set(pid, value)
        assert value == Setter.latest(pid)
      end
    end
  end
end
