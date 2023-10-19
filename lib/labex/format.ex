defmodule Labex.Format do
  @moduledoc """
  Modules for formatting and parsing messages.
  """

  @regex ~r/\{\{(.+?)\}\}/

  @doc """
  Parses string to a keyword list.
      iex> Labex.Format.parse("message:hello,12,3.4,end", "message:{{key1:str}},{{key2:int}},{{key3:float}},end")
      [key1: "hello", key2: 12, key3: 3.4]
  """
  def parse(str, format) do
    keys_and_types = extract_keys_and_types(format)
    regex = String.replace(format, @regex, "(.+)")
    [_ | values] = Regex.run(~r/#{regex}/, str)
    Enum.zip(values, keys_and_types)
    |> Enum.map(fn {value, {key, type}} -> {key, parse_func(type).(value)} end)
  end

  @spec format(binary(), Keyword.t()) :: binary()
  @doc """
  Formats a keyword list to string.

      iex> Labex.Format.format("message:{{key1}},{{key2}},{{key3}}:end", key1: "hello", key2: 12, key3: 3.4)
      "message:hello,12,3.4:end"
      iex> Labex.Format.format("message")
      "message"
  """
  def format(format, kw_list \\ []) do
    format_peace = String.split(format, @regex)
    keys = extract_keys_and_types(format) |> Keyword.keys()

    out =
      Enum.zip(format_peace, keys)
      |> Enum.reduce("", fn {peace, key}, acc -> "#{acc}#{peace}#{Keyword.get(kw_list, key)}" end)

    "#{out}#{List.last(format_peace)}"
  end

  @spec extract_keys_and_types(binary()) :: Keyword.t()
  defp extract_keys_and_types(format) do
    Regex.scan(@regex, format)
    |> Enum.map(fn [_, pattern] -> split_key_and_type(pattern) end)
  end

  @spec split_key_and_type(binary()) :: {atom(), atom()}
  defp split_key_and_type(key) do
    case String.split(key, ":") do
      [name, type] -> {String.to_atom(name), String.to_atom(type)}
      [name] -> {String.to_atom(name), nil}
    end
  end

  @spec parse_func(:float | :int | :str) :: (binary() -> any())
  defp parse_func(type) do
    case type do
      :str -> & &1
      :float -> &elem(Float.parse(&1), 0)
      :int -> &String.to_integer(&1)
      _ -> raise "Unknown type: #{type}"
    end
  end
end
