defmodule VariableTest do
  alias LabLive.Variable
  use ExUnit.Case, async: false
  use ExUnitProperties
  doctest Variable

  test "queue" do
    resource_size = 100

    for i <- 0..100 do
      name = :"name#{i}"
      max_size = Enum.random(1..resource_size)
      times_append = Enum.random(1..resource_size)
      values = repeatedly(&(:rand.uniform/0)) |> Enum.take(resource_size + 1)

      {:ok, pid} = Variable.start_link({:"#{name}", max_size: max_size})

      size =
        if max_size < times_append do
          max_size
        else
          times_append
        end

      appended = for i <- 0..(times_append - 1) do
        current_size = Variable.stats(pid).size

        if i> max_size do
          assert current_size == max_size
        else
          assert current_size == i
        end

        value = values |> Enum.at(i)
        Variable.append(pid, value)
        value
      end

      last =
        case times_append do
          0 -> :empty
          _ -> List.last(appended)
        end

      stats = Variable.stats(pid)
      in_queue = Enum.reverse(appended) |> Enum.take(max_size)
      sum = Enum.sum(in_queue)
      square_sum = Enum.sum(for x <- in_queue, do: x * x)

      assert last == Variable.latest(pid)
      assert size == stats.size
      assert_in_delta(sum, stats.sum, 1.0e-10)
      assert_in_delta(square_sum, stats.square_sum, 1.0e-10)
    end
  end
end
