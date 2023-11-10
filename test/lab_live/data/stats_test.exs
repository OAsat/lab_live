defmodule LabLive.Data.StatsTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Data.Stats
  doctest Stats

  def from_list(list \\ [], max_size \\ :inf) when is_list(list) do
    if max_size != :inf do
      if length(list) > max_size do
        raise "list size(#{length(list)}) must be same or less than max_size(#{max_size})."
      end
    end

    %Stats{
      size: length(list),
      max_size: max_size,
      sum: Enum.sum(list),
      square_sum: Enum.sum(for x <- list, do: x * x),
      queue: :queue.from_list(list)
    }
  end

  test "max_size = inf" do
    check all(values <- list_of(float(min: -1.0, max: 1.0))) do
      stats =
        Enum.reduce(values, Stats.new(:inf), fn value, stats ->
          Stats.update(stats, value)
        end)

      from_list = from_list(values)

      assert stats.max_size == :inf
      assert stats.size == from_list.size
      assert stats.queue |> :queue.to_list() == from_list.queue |> :queue.to_list()
      assert Stats.value(stats) == List.last(values) || :empty
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
        Enum.reduce(values, Stats.new(max_size), fn value, stats ->
          Stats.update(stats, value)
        end)

      valid_size =
        if max_size < length(values) do
          max_size
        else
          length(values)
        end

      from_list = from_list(values |> Enum.take(-valid_size))

      assert stats.max_size == max_size
      assert stats.size == valid_size
      assert stats.size == from_list.size
      assert stats.queue |> :queue.to_list() == from_list.queue |> :queue.to_list()
      assert_in_delta(stats.sum, from_list.sum, 1.0e-10)
      assert_in_delta(stats.square_sum, from_list.square_sum, 1.0e-10)
    end
  end
end
