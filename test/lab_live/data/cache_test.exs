defmodule LabLive.Data.CacheTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Data.Cache
  doctest Cache

  test "max_size = inf" do
    check all(values <- list_of(term())) do
      cache =
        Enum.reduce(values, Cache.new(:inf), fn value, cache ->
          Cache.update(cache, value)
        end)

      assert Cache.to_list(cache) == values
    end
  end

  test "finite max_size" do
    check all(
            max_size <- positive_integer(),
            values <- list_of(term())
          ) do
      cache =
        Enum.reduce(values, Cache.new(max_size), fn value, cache ->
          Cache.update(cache, value)
        end)

      valid_size =
        if max_size < length(values) do
          max_size
        else
          length(values)
        end

      assert Cache.to_list(cache) == Enum.take(values, -valid_size)
    end
  end
end
