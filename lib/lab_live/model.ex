defmodule LabLive.Model do
  @moduledoc """
  A module to define the format of communication with measurement instruments.

  ## Example
  ```
  #{File.read!("test/support/lakeshore350.ex")}
  ```
  """
  alias LabLive.Format

  @callback read_termination() :: String.t()
  @callback write_termination() :: String.t()
  @callback joiner() :: String.t()
  @callback read_format(key :: atom()) :: {String.t(), String.t()}
  @callback write_format(key :: atom()) :: String.t()

  @optional_callbacks read_format: 1, write_format: 1

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)

      def read_termination() do
        "\n"
      end

      def write_termination() do
        "\n"
      end

      def joiner() do
        ";"
      end

      defoverridable(read_termination: 0, write_termination: 0, joiner: 0)
    end
  end

  defp join_queries(queries, termination, joiner) do
    query =
      queries
      |> Enum.join(joiner)
      |> String.replace(termination, "")

    query <> termination
  end

  @doc """
  Returns a read query and parser function for returned answer.

      iex> {query, parser} = LabLive.Model.get_reader(Lakeshore350, :ramp, channel: 1)
      iex> query
      "RAMP? 1\\n"
      iex> parser.("1,0.2\\r\\n")
      [onoff: 1, kpermin: 0.2]
  """
  def get_reader(model, key, opts) do
    {query_fmt, answer_fmt} = model.read_format(key)
    query = (query_fmt |> Format.format(opts)) <> model.write_termination()

    parser = get_read_parser(answer_fmt, model.read_termination())

    {query, parser}
  end

  defp get_read_parser(answer_fmt, termination) do
    fn answer ->
      answer
      |> String.replace(termination, "")
      |> Format.parse(answer_fmt)
    end
  end

  @doc """
  Returns a read query for joined commands and parser function for returned answer.

      iex> {query, parser} = LabLive.Model.get_joined_reader(Lakeshore350,
      ...>   ramp: [channel: 1],
      ...>   heater: [channel: 1],
      ...>   kelvin: [channel: "A"],
      ...>   sensor: [channel: "A"]
      ...> )
      iex> query
      "RAMP? 1;HTR? 1;KRDG? A;SRDG? A\\n"
      iex> parser.("0,0.2;50.0;300.0;100.0\\r\\n")
      [ramp: [onoff: 0, kpermin: 0.2], heater: [percentage: 50.0], kelvin: [kelvin: 300.0], sensor: [ohm: 100.0]]
  """
  def get_joined_reader(model, keys_and_opts) do
    {queries, parsers} =
      keys_and_opts
      |> Enum.map(fn {key, opts} -> get_reader(model, key, opts) end)
      |> queries_and_parsers()

    query =
      queries
      |> join_queries(model.write_termination(), model.joiner())

    parser = fn answer ->
      answers = String.split(answer, model.joiner())

      results =
        for {parser, ans} <- Enum.zip(parsers, answers) do
          parser.(ans <> model.read_termination())
        end

      Enum.zip(Keyword.keys(keys_and_opts), results)
    end

    {query, parser}
  end

  defp queries_and_parsers(list) do
    {queries, parsers} =
      list
      |> Enum.reduce({[], []}, fn {query, parser}, {queries, parsers} ->
        {[query | queries], [parser | parsers]}
      end)

    {Enum.reverse(queries), Enum.reverse(parsers)}
  end

  @doc """
  Returns a write query to write.

      iex> LabLive.Model.get_writer(Lakeshore350, :setp, channel: 1, kelvin: 300.0)
      iex> "SETP 1,300.0\\n"

      iex> LabLive.Model.get_writer(Lakeshore350, :ramp, channel: 1, binary: 0, kpermin: 0.5)
      iex> "RAMP 1,0,0.5\\n"
  """
  def get_writer(model, key, opts) do
    query = model.write_format(key) |> Format.format(opts)
    query <> model.write_termination()
  end

  @doc """
  Returns a write query for joined commands.

      iex> LabLive.Model.get_joined_reader(Lakeshore350,
      ...>   ramp: [channel: 1, binary: 0, kpermin: 0.5],
      ...>   setp: [channel: 1, kelvin: 300.0],
      ...>   range: [channel: 1, level: 5]
      ...> )
      iex> "RAMP 1,0,0.5;SETP 1,300.0;RANGE 1,5\\n"
  """
  def get_joined_writer(model, keys_and_opts) do
    for {key, opts} <- keys_and_opts do
      get_writer(model, key, opts)
    end
    |> join_queries(model.write_termination(), model.joiner())
  end
end
