defmodule LabLive.Execution.WorkerTest do
  alias LabLive.Execution.Worker
  alias LabLive.ExecutionTest.SampleExecution
  import LabLive.Execution
  use ExUnit.Case

  doctest Worker

  defmodule DefSample do
    def define(module, test_pid) do
      defmodule module do
        @test_pid :erlang.pid_to_list(test_pid)
        def test_pid(), do: :erlang.list_to_pid(@test_pid)
        def a(), do: send(test_pid(), :send_from_a)
        def b(), do: send(test_pid(), :send_from_b)
      end
    end
  end

  test "diagram runs" do
    DefSample.define(SampleExecution, self())

    Worker.set_diagram(%{
      :start => {SampleExecution, :a},
      {SampleExecution, :a} => branch(true, true: {SampleExecution, :b}, false: :finish),
      {SampleExecution, :b} => :finish
    })

    Worker.start_run()

    assert_receive :send_from_a
    assert_receive :send_from_b

    assert Worker.get_state().status == :finish
  end
end
