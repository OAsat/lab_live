defmodule GettableTest do
  alias LabLive.Gettable
  use ExUnit.Case
  use ExUnitProperties

  doctest Gettable

  test "getter/0" do
    check all(
            start <- integer(),
            n_iter <- non_negative_integer()
          ) do
      {:ok, counter} = Agent.start_link(fn -> start end)

      getter = fn ->
        Agent.update(counter, &(&1 + 1))
        Agent.get(counter, & &1)
      end

      {:ok, pid} = GenServer.start_link(Gettable, getter)

      for i <- 0..n_iter do
        assert start + i + 1 == Gettable.get(pid)
        assert start + i + 1 == Gettable.latest(pid)
      end
    end
  end
end
