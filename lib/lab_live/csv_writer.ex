defmodule LabLive.CsvWriter do
  @moduledoc """
  Functions for writing data to csv.
  """

  import LabLive.PropertyManager

  @doc """
  Returns header string with comment-out.

      iex> labels = %{a: "label a", b: "label b", c: "label c"}
      iex> values = [a: 10, b: 1.23, c: "value"]
      iex> order = [:b, :a, :c]
      iex> LabLive.CsvWriter.commented_header(labels, values, order)
      "#label b: 1.23\\n#label a: 10\\n#label c: value"
  """
  def commented_header(labels, values, order, comment \\ "#") do
    for key <- order do
      "#{comment}#{labels[key]}: #{values[key]}"
    end
    |> Enum.join("\n")
  end

  @doc """
  Returns header string representing column labels.

      iex> labels = %{x: "x(mm)", y: "y(cm)", z: "z(m)"}
      iex> order = [:y, :x, :z]
      iex> LabLive.CsvWriter.columns(labels, order)
      "y(cm),x(mm),z(m)"
  """
  def columns(labels, order, joiner \\ ",") do
    for key <- order do
      labels[key]
    end
    |> Enum.join(joiner)
  end

  def data_to_string(values, order, joiner \\ ",") do
    for key <- order do
      to_string(values[key])
    end
    |> Enum.join(joiner)
  end

  def time_id() do
    Timex.now("Japan")
    |> Timex.format!("{YY}{0M}{0D}_{0h24}{0m}{0s}")
  end

  def init_file(filepath, header) do
    File.open(filepath, [:exclusive], fn file ->
      IO.binwrite(file, header)
    end)
  end

  def append_to_file(filepath, content, newline \\ "\n") do
    File.open(filepath, [:append], fn file ->
      IO.binwrite(file, content <> newline)
    end)
  end

  def init_csv(filepath_key, column_keys, comment_keys) do
    comment = commented_header(labels(comment_keys), get_many(comment_keys), comment_keys)
    cols = columns(labels(column_keys), column_keys)
    header = "#{comment}\n#{cols}\n"

    init_file(get(filepath_key), header)
  end

  def write_csv(filepath_key, column_keys) do
    data_str = data_to_string(get_many(column_keys), column_keys)
    append_to_file(get(filepath_key), data_str)
  end
end
