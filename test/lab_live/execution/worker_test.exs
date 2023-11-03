defmodule LabLive.Execution.WorkerTest do
  alias LabLive.Execution.Worker
  use ExUnit.Case

  doctest Worker

  defmodule DefSample do
    def define(module, test_pid) do
      defmodule module do
        @test_pid :erlang.pid_to_list(test_pid)
        def test_pid(), do: :erlang.list_to_pid(@test_pid)
        def run(), do: send(test_pid(), :send_from_sample_execution)
      end
    end
  end

  test "diagram runs" do
    DefSample.define(SampleExecution, self())

    Worker.set_diagram(%{
      :start => {SampleExecution, :run},
      {SampleExecution, :run} => :finish
    })

    Worker.start()

    assert_receive :send_from_sample_execution
  end
end
