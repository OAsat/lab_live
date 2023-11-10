defmodule LabLiveTest do
  use ExUnit.Case
  doctest LabLive

  test "start_data/2" do
    start_supervised(
      {DynamicSupervisor, strategy: :one_for_one, name: LabLive.Data.TestSupervisor}
    )

    {:ok, pid} =
      LabLive.start_data([init: 10, name: :test_start_data], LabLive.Data.TestSupervisor)

    assert LabLive.Data.get(pid) == 10

    {:override, ^pid} =
      LabLive.start_data([init: 20, name: :test_start_data], LabLive.Data.TestSupervisor)

    assert LabLive.Data.get(pid) == 20
  end
end
