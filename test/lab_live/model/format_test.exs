defmodule LabLive.Model.FormatTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Model.Format

  doctest Format

  def query_stream(excluded \\ ["{", "}"]) do
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

  describe "format/2" do
    test "with properties" do
      check all({list, keys, values} <- query_stream()) do
        params = Enum.zip(keys, values)

        format =
          Enum.reduce(list, "", fn i, acc ->
            if is_atom(i), do: acc <> "{{#{i}}}", else: acc <> i
          end)

        expected =
          Enum.reduce(list, "", fn i, acc ->
            if is_atom(i), do: acc <> "#{params[i]}", else: acc <> i
          end)

        assert expected == Format.format(format, params)
      end
    end

    test "for simple use case" do
      check all(
              term1 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)]),
              term2 <- one_of([boolean(), integer(), binary(), float(), atom(:alphanumeric)])
            ) do
        assert "ab #{term1} cd #{term2} ef" ==
                 Format.format("ab {{term1}} cd {{term2}} ef", term1: term1, term2: term2)
      end
    end
  end

  describe "parse/2" do
    test "with properties" do
      joiners = [",", ":", " ", "/", ";", "\\"] |> Enum.map(&constant(&1))

      check all(
              joiner <- one_of(joiners),
              {list, keys, values} <- query_stream(["{", "}", joiner])
            ) do
        params = Enum.zip(keys, values)

        type = fn
          str when is_binary(str) -> :str
          float when is_float(float) -> :float
          int when is_integer(int) -> :int
        end

        format =
          for i <- list do
            if is_atom(i), do: "{{#{i}:#{type.(params[i])}}}", else: i
          end
          |> Enum.join(joiner)

        to_be_parsed =
          for i <- list do
            if is_atom(i), do: "#{params[i]}", else: i
          end
          |> Enum.join(joiner)

        assert params == Format.parse(to_be_parsed, format)
      end
    end

    test "for simple use case" do
      check all(
              val1 <- string(:alphanumeric, min_length: 1),
              val2 <- float(),
              val3 <- integer()
            ) do
        assert [val3: val3, val2: val2, val1: val1] ==
                 Format.parse(
                   "s #{val3},#{val2},#{val1} e",
                   "s {{val3:int}},{{val2:float}},{{val1:str}} e"
                 )
      end
    end
  end
end
