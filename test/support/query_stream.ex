defmodule Test.Support.QueryStream do
  import StreamData

  defp str(excluded) do
    filter(string(:ascii, max_length: 10), &(!String.contains?(&1, excluded)))
  end

  defp key, do: atom(:alphanumeric)
  def type, do: one_of([:str, :float, :int, nil] |> Enum.map(&constant(&1)))

  def query_components(excluded \\ ["{", "}"]) do
    uniq_list_of(one_of([str(excluded), key()]), max_length: 10)
  end

  def only_atoms(list), do: Enum.filter(list, &is_atom(&1))

  def to_format(query_components, keys_and_types) do
    query_components
    |> Enum.map(fn i ->
      with true <- is_atom(i),
           nil <- keys_and_types[i] do
        "{{#{i}}}"
      else
        false -> i
        type -> "{{#{i}:#{type}}}"
      end
    end)
    |> Enum.join()
  end

  # defp value(:str), do: str()
  # defp value(:float), do: float()
  # defp value(:int), do: integer()
  # defp value(nil), do: one_of(value())
  # defp type_and_value, do: bind(type(), fn t -> bind(value(t), fn v -> {t, v} end) end)

  def input_stream(excluded \\ ["{", "}"]) do
    map(query_stream(excluded), fn {str_or_key, keys, values} ->
      params = Enum.zip(keys, values)
      {to_input_format(str_or_key), to_formatted_input(str_or_key, params), params}
    end)
  end

  def output_stream(excluded \\ ["{", "}"], joiner \\ ",") do
    map(query_stream([joiner | excluded]), fn {str_or_key, keys, values} ->
      params = Enum.zip(keys, values)

      {to_output_format(str_or_key, params, joiner),
       to_output_example(str_or_key, params, joiner), params}
    end)
  end

  defp query_stream(excluded) do
    value = one_of([str(excluded), float(), integer()])

    bind(query_components(excluded), fn list ->
      bind(list_of(value, length: length(only_atoms(list))), fn values ->
        constant({list, only_atoms(list), values})
      end)
    end)
  end

  defp to_input_format(str_or_key) do
    str_or_key
    |> Enum.reduce("", fn i, acc ->
      if is_atom(i), do: acc <> "{{#{i}}}", else: acc <> i
    end)
  end

  defp to_formatted_input(str_or_key, params) do
    Enum.reduce(str_or_key, "", fn i, acc ->
      if is_atom(i), do: acc <> "#{params[i]}", else: acc <> i
    end)
  end

  defp type(value) do
    case value do
      str when is_binary(str) -> :str
      float when is_float(float) -> :float
      int when is_integer(int) -> :int
    end
  end

  defp to_output_format(str_or_key, params, joiner) do
    for i <- str_or_key do
      if is_atom(i), do: "{{#{i}:#{type(params[i])}}}", else: i
    end
    |> Enum.join(joiner)
  end

  defp to_output_example(str_or_key, params, joiner) do
    for i <- str_or_key do
      if is_atom(i), do: "#{params[i]}", else: i
    end
    |> Enum.join(joiner)
  end
end
