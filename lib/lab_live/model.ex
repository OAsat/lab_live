defmodule LabLive.Model do
  @moduledoc """
  A module to define the format of communication with measurement instruments.

  ### Example
  `lakeshore350.model.json`
  ```json
  #{File.read!("test/support/lakeshore350.model.json")}
  ```
  """
  defstruct name: "",
            character: %{write_termination: "\n", read_termination: "\n", joiner: ","},
            query: %{}

  alias LabLive.Model.Format

  def from_json_file(path) do
    File.read!(path)
    |> from_json()
  end

  def from_json(json) do
    json
    |> Jason.decode!(keys: :atoms)
    |> from_map()
  end

  def from_map(map) do
    struct(__MODULE__, map)
  end

  def get_format_pair(%__MODULE__{} = model, query_key, params) do
    {format_input(model, query_key, params), get_output_parser(model, query_key)}
  end

  @doc """
  Formats the input parameters to a query string.

      iex> model = %LabLive.Model{query: %{param: %{input: "GET:{{val1}},{{val2}}"}}}
      iex> LabLive.Model.format_input(model, :param, val1: 1.2, val2: 3)
      "GET:1.2,3\\n"
      iex> LabLive.Model.format_input(model, :param2, val1: 1.2, val2: 3)
      {:error, :key_not_found}

      iex> model = LabLive.Model.from_json_file("test/support/lakeshore350.model.json")
      iex> LabLive.Model.format_input(model, :pid, channel: 2, p: 100, i: 50, d: 0)
      "PID 2,100,50,0\\n"
  """
  def format_input(%__MODULE__{} = model, query_key, params) do
    case model.query[query_key] do
      nil -> {:error, :key_not_found}
      %{input: format} -> Format.format(format, params) <> model.character.write_termination
    end
  end

  @doc """
  Returns a parser function for returned answer.

      iex> model = LabLive.Model.from_json_file("test/support/lakeshore350.model.json")
      iex> parser = LabLive.Model.get_output_parser(model, :pid?)
      iex> parser.("100,50,0\\r\\n")
      %{p: 100.0, i: 50.0, d: 0.0}
      iex> LabLive.Model.get_output_parser(model, :pid)
      nil
      iex> LabLive.Model.get_output_parser(model, :_pid)
      {:error, :key_not_found}
  """
  def get_output_parser(%__MODULE__{} = model, query_key) do
    case model.query[query_key] do
      nil ->
        {:error, :key_not_found}

      %{output: format} ->
        fn output ->
          String.replace(output, model.character.read_termination, "")
          |> Format.parse(format)
          |> Enum.into(%{})
        end

      %{} ->
        nil
    end
  end
end
