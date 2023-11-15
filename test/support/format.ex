defmodule Test.Support.Format do
  import StreamData

  def str_or_key(excluded) do
    str = filter(string(:ascii, max_length: 10), &(!String.contains?(&1, excluded)))
    key = atom(:alphanumeric)
    uniq_list_of(one_of([str, key]), max_length: 10)
  end

  # defp type, do: one_of([:str, :float, :int, nil])

  # def gen_params(str_or_key) do
  #   atoms = only_atoms(str_or_key)
  #   bind(list_of(value, length: length(only_atoms(list))), fn values ->
  #     constant({list, only_atoms(list), values})
  #   end)
  # end

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
    str = filter(string(:ascii, max_length: 10), &(!String.contains?(&1, excluded)))
    key = atom(:alphanumeric)
    value = one_of([str, float(), integer()])
    str_or_key = uniq_list_of(one_of([str, key]), max_length: 10)

    bind(str_or_key, fn list ->
      bind(list_of(value, length: length(only_atoms(list))), fn values ->
        constant({list, only_atoms(list), values})
      end)
    end)
  end

  defp only_atoms(list) do
    Enum.filter(list, &is_atom(&1))
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
