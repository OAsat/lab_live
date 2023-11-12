defmodule LabLive.Data.LoopTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Data.Loop
  doctest Loop

  test "looping" do
    check all(
            list <- list_of(term(), min_length: 1, max_length: 100),
            n_step <- non_negative_integer(),
            n_step > 0
          ) do
      loop = Loop.new(list)
      assert Enum.at(list, 0) == Loop.value(loop)

      result =
        Enum.reduce(1..n_step, loop, fn _, acc ->
          Loop.update(acc, nil)
        end)

      assert result.count == n_step
      assert Enum.at(list, rem(n_step, length(list))) == Loop.value(result)
      assert loop == Loop.reset(result)
    end
  end
end
