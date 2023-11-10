defmodule LabLive.Data.Csv do
  @moduledoc """
  Struct representing a csv file.
  """
  defstruct [:path_function, :column_labels, :comment_labels]
  alias LabLive.Data
  @behaviour Data.Behaviour
  require Logger

  @type column_labels() :: [{atom(), String.t()}]
  @type comment_labels() :: [{atom(), String.t()}]

  @type t() :: %__MODULE__{
          path_function: function(),
          column_labels: column_labels(),
          comment_labels: comment_labels()
        }

  @impl Data.Behaviour
  def new({path_function, column_labels, comment_labels}) when is_function(path_function, 0) do
    %__MODULE__{
      path_function: path_function,
      column_labels: column_labels,
      comment_labels: comment_labels
    }
  end

  @doc """
  Returns the path of the csv file.

      iex> path_function = fn -> "path/to/file.csv" end
      iex> csv = LabLive.Data.Csv.new({path_function, [], []})
      iex> LabLive.Data.Csv.value(csv)
      "path/to/file.csv"
  """
  @impl Data.Behaviour
  def value(%__MODULE__{path_function: path_function}) do
    path_function.()
  end

  @impl Data.Behaviour
  def update(
        %__MODULE__{path_function: path_function, column_labels: column_labels} = csv,
        new_data
      ) do
    append_to_file(path_function.(), data_to_string(column_labels, new_data))
    csv
  end

  @impl Data.Behaviour
  def to_string(%__MODULE__{} = csv) do
    "#{value(csv)}"
  end

  def create(%__MODULE__{} = csv, comment_values) do
    create_file(csv.path_function.(), header_string(csv, comment_values))
  end

  @doc """
  Returns header string with commented-out values.

      iex> columns = [x: "x(mm)", y: "y(cm)", z: "z(km)"]
      iex> comments = [b: "label b", a: "label a", c: "label c"]
      iex> values = [a: 10, b: 1.23, c: "value"]
      iex> csv = LabLive.Data.Csv.new({fn -> "" end, columns, comments})
      iex> LabLive.Data.Csv.header_string(csv, values)
      "#label b: 1.23\\n#label a: 10\\n#label c: value\\nx(mm),y(cm),z(km)\\n"
  """
  def header_string(%__MODULE__{} = csv, comment_values) do
    "#{header_comment(csv.comment_labels, comment_values)}\n" <>
      "#{header_column(csv.column_labels)}\n"
  end

  defp header_column(column_labels) do
    column_labels |> Keyword.values() |> Enum.join(",")
  end

  defp data_to_string(labels, values) do
    for key <- Keyword.keys(labels) do
      "#{LabLive.Data.Protocol.value(values[key])}"
    end
    |> Enum.join(",")
  end

  defp header_comment(comment_labels, comment_values) do
    for {key, comment_label} <- comment_labels do
      "##{comment_label}: #{comment_values[key]}"
    end
    |> Enum.join("\n")
  end

  defp create_file(filepath, header) when is_binary(filepath) do
    File.open(filepath, [:exclusive], fn file -> IO.binwrite(file, header) end)
    Logger.info("Initialized csv file: #{filepath}")
  end

  defp append_to_file(filepath, content) when is_binary(filepath) do
    File.open(filepath, [:append], fn file ->
      IO.binwrite(file, content <> "\n")
    end)
  end
end
