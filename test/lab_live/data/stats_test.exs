defmodule LabLive.Data.StatsTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Data.Stats
  doctest Stats

  test "max_size = inf" do
    check all(values <- list_of(float(min: -1.0, max: 1.0))) do
      stats =
        Enum.reduce(values, %Stats{}, fn value, stats ->
          Stats.append(stats, value)
        end)

      from_list = Stats.new(values)

      assert stats.max_size == :inf
      assert stats.size == from_list.size
      assert stats.queue |> :queue.to_list() == from_list.queue |> :queue.to_list()
      assert_in_delta(stats.sum, from_list.sum, 1.0e-10)
      assert_in_delta(stats.square_sum, from_list.square_sum, 1.0e-10)
    end
  end

  test "finite max_size" do
    check all(
            max_size <- positive_integer(),
            values <- list_of(float(min: -1.0, max: 1.0))
          ) do
      stats =
        Enum.reduce(values, Stats.new([], max_size), fn value, stats ->
          Stats.append(stats, value)
        end)

      valid_size =
        if max_size < length(values) do
          max_size
        else
          length(values)
        end

      from_list = Stats.new(values |> Enum.take(-valid_size))

      assert stats.max_size == max_size
      assert stats.size == valid_size
      assert stats.size == from_list.size
      assert stats.queue |> :queue.to_list() == from_list.queue |> :queue.to_list()
      assert_in_delta(stats.sum, from_list.sum, 1.0e-10)
      assert_in_delta(stats.square_sum, from_list.square_sum, 1.0e-10)
    end
  end
end
