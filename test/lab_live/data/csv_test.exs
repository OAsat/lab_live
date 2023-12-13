defmodule LabLive.Data.CsvTest do
  alias LabLive.Data.Csv
  alias LabLive.Data
  use ExUnit.Case
  doctest LabLive.Data.Csv

  test "data_to_string/2" do
    labels = [a: "A", b: "B", c: "C"]
    values = [a: 1, b: Data.Iterator.new([2, 3]), c: Data.Loop.new([4, 5])]
    assert "1,not_started,4" == Csv.data_to_string(labels, values)
  end
end
