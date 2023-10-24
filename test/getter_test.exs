defmodule GetterTest do
  alias LabLive.Getter
  use ExUnit.Case
  use ExUnitProperties

  doctest Getter

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

      {:ok, pid} = GenServer.start_link(Getter, getter)

      for i <- 0..n_iter do
        assert start + i + 1 == Getter.get(pid)
        assert start + i + 1 == Getter.latest(pid)
      end
    end
  end
end
