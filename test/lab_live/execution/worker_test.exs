defmodule LabLive.Execution.WorkerTest do
  alias LabLive.Execution.Worker
  use ExUnit.Case

  doctest Worker

  test "sequential run" do
    this = self()

    diagram = [
      fn -> send(this, :running_1) end,
      fn -> send(this, :running_2) end
    ]

    {:ok, pid} = Worker.start_link()
    Worker.set_diagram(pid, diagram)
    Worker.start_run(pid)

    assert_receive :running_1
    assert_receive :running_2
  end

  test "iteration" do
    alias LabLive.Data
    this = self()

    {:ok, iter1} = Data.start_link(init: Data.Iterator.new([1, 2, 3]))
    {:ok, iter2} = Data.start_link(init: Data.Iterator.new([4, 5]))
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    func = fn ->
      Agent.update(counter, &(1 + &1))
      send(this, {Agent.get(counter, & &1), Data.value(iter1), Data.value(iter2)})
    end

    diagram = [iterate: iter1, do: [iterate: iter2, do: func]]

    {:ok, pid} = Worker.start_link()
    Worker.set_diagram(pid, diagram)
    Worker.start_run(pid)

    assert_receive {1, 1, 4}
    assert_receive {2, 1, 5}
    assert_receive {3, 2, 4}
    assert_receive {4, 2, 5}
    assert_receive {5, 3, 4}
    assert_receive {6, 3, 5}
  end
end
