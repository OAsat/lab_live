defmodule LabLive.Model do
  @moduledoc """
  A module to define the format of communication with measurement instruments.

  ### Example
  #### `.ex` file
  ```
  #{File.read!("test/support/models/lakeshore350.ex")}
  ```

  #### `.json` file
  ```json
  #{File.read!("test/support/models/lakeshore350.model.json")}
  ```

  #### `.toml` file
  ```toml
  #{File.read!("test/support/models/lakeshore350.model.toml")}
  ```
  """
  defstruct name: "",
            character: %{input_term: "\n", output_term: "\n", joiner: ";"},
            query: %{}

  @type t() :: %__MODULE__{
          name: String.t(),
          character: %{input_term: String.t(), output_term: String.t(), joiner: String.t()},
          query: queries()
        }

  @type queries() :: %{atom() => %{(:input | :output) => String.t()}}

  alias LabLive.Model.Format

  def from_file(path) do
    case Path.extname(path) do
      ".json" -> from_json_file(path)
      ".toml" -> from_toml_file(path)
    end
  end

  def from_toml_file(path) do
    File.read!(path)
    |> from_toml()
  end

  def from_toml(toml) do
    toml
    |> Toml.decode!(keys: :atoms)
    |> from_map()
  end

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

      iex> model = Lakeshore350.model()
      iex> LabLive.Model.format_input(model, :pid, channel: 2, p: 100, i: 50, d: 0)
      "PID 2,100,50,0\\n"
  """
  def format_input(%__MODULE__{} = model, query_key, params) do
    case model.query[query_key] do
      nil -> {:error, :key_not_found}
      %{input: format} -> Format.format(format, params) <> model.character.input_term
    end
  end

  @doc """
  Returns a parser function for returned answer.

      iex> model = Lakeshore350.model()
      iex> parser = LabLive.Model.get_output_parser(model, :pid?)
      iex> parser.("100,50,0\\r\\n")
      %{p: 100.0, i: 50.0, d: 0.0}
      iex> LabLive.Model.get_output_parser(model, :pid)
      nil
      iex> LabLive.Model.get_output_parser(model, :_pid)
      {:error, :key_not_found}


      iex> model = %LabLive.Model{query: %{param: %{output: "NO_KEY"}}}
      iex> parser = LabLive.Model.get_output_parser(model, :param)
      iex> parser.("NO_KEY\\n")
      %{}
  """
  def get_output_parser(%__MODULE__{} = model, query_key) do
    case model.query[query_key] do
      nil ->
        {:error, :key_not_found}

      %{output: format} ->
        fn output ->
          String.replace(output, model.character.output_term, "")
          |> Format.parse(format)
          |> Enum.into(%{})
        end

      %{} ->
        nil
    end
  end

  @doc """
  Returns a input query for joined commands.

      iex> model = Lakeshore350.model()
      iex> LabLive.Model.format_joined_input(model,
      ...>   ramp: [channel: 1, binary: 0, kpermin: 0.5],
      ...>   setp: [channel: 1, kelvin: 300.0],
      ...>   range: [channel: 1, level: 5]
      ...> )
      "RAMP 1,0,0.5;SETP 1,300.0;RANGE 1,5\\n"
  """
  def format_joined_input(%__MODULE__{} = model, queries) when is_list(queries) do
    for {query_key, params} <- queries do
      format_input(model, query_key, params)
    end
    |> join_queries(model.character.input_term, model.character.joiner)
  end

  defp join_queries(queries, termination, joiner) do
    query =
      queries
      |> Enum.join(joiner)
      |> String.replace(termination, "")

    query <> termination
  end

  @doc """
  Returns a parser function for the answer of the joined commands.

      iex> model = Lakeshore350.model()
      iex> parser = LabLive.Model.get_joined_output_parser(model, [:ramp?, :heater?, :temp?, :temp?, :sensor?])
      iex> parser.("0,0.2;50.0;20.0;300.0;100.0\\r\\n")
      [ramp?: %{onoff: 0, kpermin: 0.2}, heater?: %{percentage: 50.0}, temp?: %{kelvin: 20.0}, temp?: %{kelvin: 300.0}, sensor?: %{ohm: 100.0}]
  """
  def get_joined_output_parser(%__MODULE__{} = model, query_keys) when is_list(query_keys) do
    fn answer ->
      answer
      |> String.replace(model.character.output_term, "")
      |> String.split(model.character.joiner)
      |> Enum.zip(query_keys)
      |> Enum.map(fn {str, key} -> {key, get_output_parser(model, key).(str)} end)
    end
  end

  @doc """
  Returns a input query and parser function for joined commands.

      iex> model = Lakeshore350.model()
      iex> {query, parser} = LabLive.Model.get_joined_format_pair(model,
      ...>   ramp?: [channel: 1],
      ...>   heater?: [channel: 1],
      ...>   temp?: [channel: "A"],
      ...>   sensor?: [channel: "B"],
      ...>   sensor?: [channel: "C"]
      ...> )
      iex> query
      "RAMP? 1;HTR? 1;KRDG? A;SRDG? B;SRDG? C\\n"
      iex> parser.("1,0.2;50.0;20.0;300.0;100.0\\r\\n")
      [ramp?: %{onoff: 1, kpermin: 0.2}, heater?: %{percentage: 50.0}, temp?: %{kelvin: 20.0}, sensor?: %{ohm: 300.0}, sensor?: %{ohm: 100.0}]
  """
  def get_joined_format_pair(%__MODULE__{} = model, queries) do
    {format_joined_input(model, queries), get_joined_output_parser(model, Keyword.keys(queries))}
  end
end
