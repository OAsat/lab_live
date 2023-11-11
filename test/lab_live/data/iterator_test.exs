defmodule LabLive.Data.IteratorTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Data.Iterator
  doctest Iterator

  test "enumeration" do
    check all(
            list <- list_of(term(), min_length: 1, max_length: 100),
            n_step <- non_negative_integer(),
            n_step > 0
          ) do
      iter = Iterator.new(list)
      assert :not_started == Iterator.value(iter)
      assert false == Iterator.finish?(iter)

      iter =
        Enum.reduce(1..n_step, Iterator.new(list), fn _, acc ->
          Iterator.update(acc, nil)
        end)

      if n_step > length(list) do
        assert :finished == Iterator.value(iter)
        assert true == Iterator.finish?(iter)
      else
        assert Enum.at(list, n_step - 1) == Iterator.value(iter)
        assert false == Iterator.finish?(iter)
      end

      assert Iterator.new(list) == Iterator.reset(iter)
    end
  end
end
