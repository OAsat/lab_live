defmodule QueueTest do
  alias LabLive.Queue
  use ExUnit.Case, async: false
  use ExUnitProperties
  doctest Queue

  test "queue" do
    resource_size = 100

    for i <- 0..100 do
      name = :"name#{i}"
      max_size = Enum.random(1..resource_size)
      times_append = Enum.random(1..resource_size)
      values = repeatedly(&:rand.uniform/0) |> Enum.take(resource_size + 1)

      {:ok, pid} = Queue.start_link({:"#{name}", max_size: max_size})

      size =
        if max_size < times_append do
          max_size
        else
          times_append
        end

      appended =
        for i <- 0..(times_append - 1) do
          current_size = Queue.stats(pid).size

          if i > max_size do
            assert current_size == max_size
          else
            assert current_size == i
          end

          value = values |> Enum.at(i)
          Queue.append(pid, value)
          value
        end

      last =
        case times_append do
          0 -> :empty
          _ -> List.last(appended)
        end

      stats = Queue.stats(pid)
      in_queue = Enum.reverse(appended) |> Enum.take(max_size)
      sum = Enum.sum(in_queue)
      square_sum = Enum.sum(for x <- in_queue, do: x * x)

      assert last == Queue.latest(pid)
      assert size == stats.size
      assert in_queue == Queue.as_list(pid) |> Enum.reverse()
      assert_in_delta(sum, stats.sum, 1.0e-10)
      assert_in_delta(square_sum, stats.square_sum, 1.0e-10)
    end
  end

  test "single" do
    {:ok, pid} = Queue.start_link(:test_single)
    assert :empty == Queue.latest(pid)
    assert :ok == Queue.append(pid, 10)
    assert 10 == Queue.latest(pid)
    assert 10 == Queue.append(pid, 20)
    assert 20 == Queue.latest(pid)
  end

  test "non number" do
    resource_size = 100

    for i <- 0..100 do
      name = :"non_number#{i}"
      max_size = Enum.random(1..resource_size)
      times_append = Enum.random(1..resource_size)
      values = atom(:alphanumeric) |> Enum.take(resource_size + 1)

      {:ok, pid} = Queue.start_link({:"#{name}", max_size: max_size})

      size =
        if max_size < times_append do
          max_size
        else
          times_append
        end

      appended =
        for i <- 0..(times_append - 1) do
          current_size = Queue.stats(pid).size

          if i > max_size do
            assert current_size == max_size
          else
            assert current_size == i
          end

          value = values |> Enum.at(i)
          Queue.append(pid, value)
          value
        end

      last =
        case times_append do
          0 -> :empty
          _ -> List.last(appended)
        end

      stats = Queue.stats(pid)
      in_queue = Enum.reverse(appended) |> Enum.take(max_size)

      assert last == Queue.latest(pid)
      assert size == stats.size
      assert in_queue == Queue.as_list(pid) |> Enum.reverse()
    end
  end
end
