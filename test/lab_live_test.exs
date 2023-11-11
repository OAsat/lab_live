defmodule LabLiveTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest LabLive

  setup do
    start_supervised(
      {DynamicSupervisor, strategy: :one_for_one, name: LabLive.Data.TestSupervisor}
    )

    :ok
  end

  test "start_data/2" do
    {:ok, pid} =
      LabLive.start_data(:start_data_test, [init: 10], LabLive.Data.TestSupervisor)

    assert LabLive.Data.get(pid) == 10
    assert LabLive.Data.get(:start_data_test) == 10

    {:override, ^pid} =
      LabLive.start_data(:start_data_test, [init: 20], LabLive.Data.TestSupervisor)

    assert LabLive.Data.get(pid) == 20
    assert LabLive.Data.get(:start_data_test) == 20
  end

  test "start_many_data/2" do
    many_data = [
      start_many_data_test1: [init: 10],
      start_many_data_test2: [init: 20]
    ]

    [start_many_data_test1: {:ok, pid1}, start_many_data_test2: {:ok, pid2}] =
      LabLive.start_many_data(many_data, LabLive.Data.TestSupervisor)

    assert LabLive.Data.get(pid1) == 10
    assert LabLive.Data.get(pid2) == 20
  end

  test "data_to_markdown/1" do
    many_data = [
      data_to_markdown_test1: [init: 10, label: "label1"],
      data_to_markdown_test2: [init: 20, visible?: false],
      data_to_markdown_test3: [init: 30],
      data_to_markdown_test4: [init: LabLive.Data.Iterator.new([1, 2]), label: "label4"]
    ]
    LabLive.start_many_data(many_data, LabLive.Data.TestSupervisor)

    expected = """
    |key|label|value|
    |--|--|--|
    |data_to_markdown_test1|label1|10|
    |data_to_markdown_test3||30|
    |data_to_markdown_test4|label4|not_started <- [1, 2]|
    """

    assert expected == LabLive.data_to_markdown(many_data)
  end
end
