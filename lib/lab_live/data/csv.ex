defmodule LabLive.Data.Csv do
  @moduledoc """
  Functions for writing data to csv.
  """
  defstruct [:path, :column_labels, :comment_labels]

  import LabLive.Data

  @type column_labels() :: [{atom(), String.t()}]
  @type comment_labels() :: [{atom(), String.t()}]

  @type t() :: %__MODULE__{
          path: String.t(),
          column_labels: column_labels(),
          comment_labels: comment_labels()
        }

  def new(path, column_labels, comment_labels) do
    %__MODULE__{
      path: path,
      column_labels: column_labels,
      comment_labels: comment_labels
    }
  end

  def init_csv(key, comment_values) when is_atom(key) do
    get(key) |> init_csv(comment_values)
  end

  def init_csv(%__MODULE__{} = csv, comment_values) do
    comment = data_comment(csv.comment_labels, comment_values)
    header = header(csv.column_labels)
    content = "#{comment}\n#{header}\n"
    init_file(csv.path, content)
  end

  @doc """
  Returns header string with comment-out.

      iex> labels = [b: "label b", a: "label a", c: "label c"]
      iex> values = [a: 10, b: 1.23, c: "value"]
      iex> LabLive.Data.Csv.data_comment(labels, values)
      "#label b: 1.23\\n#label a: 10\\n#label c: value"
  """
  def data_comment(comment_labels, comment_values, comment \\ "#") do
    for {key, comment_label} <- comment_labels do
      "#{comment}#{comment_label}: #{comment_values[key]}"
    end
    |> Enum.join("\n")
  end

  @doc """
  Returns a header string.
      iex> labels = [x: "label x", y: "label y", z: "label z"]
      iex> LabLive.Data.Csv.header(labels)
      "label x,label y,label z"
  """
  def header(column_labels, joiner \\ ",") do
    Keyword.values(column_labels) |> Enum.join(joiner)
  end

  def init_file(filepath, header) do
    File.open(filepath, [:exclusive], fn file -> IO.binwrite(file, header) end)
  end

  @doc """
  Returns header string representing column labels.

      iex> labels = %{x: "x(mm)", y: "y(cm)", z: "z(m)"}
      iex> order = [:y, :x, :z]
      iex> LabLive.Data.Csv.column_labels(labels, order)
      "y(cm),x(mm),z(m)"
  """
  def column_labels(labels, order, joiner \\ ",") do
    for key <- order do
      labels[key]
    end
    |> Enum.join(joiner)
  end

  def append(key, values) when is_atom(key) do
    get(key) |> append(values)
  end

  def append(%__MODULE__{} = csv, values) do
    data_str = data_to_string(values, csv.column_labels)
    append_to_file(csv.path, data_str)
  end

  @doc """
  Returns data string representing values.

      iex> labels = [x: "x(mm)", y: "y(cm)", z: "z(m)"]
      iex> values = [x: 10, y: 1.23, z: 0.001]
      iex> LabLive.Data.Csv.data_to_string(labels, values)
      "10,1.23,0.001"
  """
  def data_to_string(labels, values, joiner \\ ",") do
    for key <- Keyword.keys(labels) do
      to_string(values[key])
    end
    |> Enum.join(joiner)
  end

  def append_to_file(filepath, content, newline \\ "\n") do
    File.open(filepath, [:append], fn file ->
      IO.binwrite(file, content <> newline)
    end)
  end
end
