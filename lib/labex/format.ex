defmodule Labex.Format do
  @doc """
  Formats a keyword list to string.
      iex> Labex.Format.format("message:{key1},{key2},{key3},{key1}", [key1: "hello", key2: 12, key3: 3.4])
      "message:hello,12,3.4,hello"
  """
  def format(format, param_list) do
    Regex.replace(
      ~r/\{(.+?)\}/,
      format,
      fn _, name -> get_from_keywordlist(param_list, name) |> to_string() end
    )
  end

  @doc """
  Parses string to a keyword list.
      iex> Labex.Format.parse("message:hello,12,3.4", "message:{key1:str},{key2:int},{key3:float}")
      [key1: "hello", key2: 12, key3: 3.4]
  """
  def parse(str, format) do
    {regex, keys, types} = expand_parse_format(format)
    [_ | values] = Regex.run(~r/#{regex}/, str)

    Enum.zip([values, keys, types])
    |> Enum.map(fn {value, key, type} -> {key, parse_func(type).(value)} end)
  end

  defp expand_parse_format(format) do
    {regex, keys, types} = Regex.scan(~r/\{(.+?):(.+?)\}/, format)
    |> Enum.reduce(
      {format, [], []},
      fn [pattern, key, type], {regex, keys, types} ->
        {
          Regex.replace(~r/#{pattern}/, regex, "(.+)"),
          [String.to_atom(key) | keys],
          [type | types]
        }
      end
    )
    {regex, Enum.reverse(keys), Enum.reverse(types)}
  end

  defp parse_func(type) do
    case type do
      "str" -> & &1
      "float" -> &elem(Float.parse(&1), 0)
      "int" -> &String.to_integer(&1)
    end
  end

  defp get_from_keywordlist(keyword_list, name) do
    # keyword-list to map
    Enum.into(keyword_list, %{})
    |> Map.get(String.to_atom(name))
  end
end
