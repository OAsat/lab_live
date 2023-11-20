defmodule LabLive.Model.FormatTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Model.Format
  import Test.Support.QueryStream

  doctest Format

  # TODO: Implement
  test "extract_keys_and_types/1" do
    check all(
            query_components <- query_components(),
            types <- list_of(type(), length: length(only_atoms(query_components)))
          ) do
      keys = only_atoms(query_components)
      keys_and_types = Enum.zip(keys, types)

      format =
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

      assert keys_and_types == Format.extract_keys_and_types(format)
    end
  end

  describe "format/2" do
    test "with properties" do
      check all({format, expected, params} <- input_stream()) do
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
      joiners = [",", ":", " ", "/", ";", "\\", "\r", "\n"] |> Enum.map(&constant(&1))

      check all(
              joiner <- one_of(joiners),
              {format, example, params} <- output_stream(["{", "}"], joiner)
            ) do
        assert params == Format.parse(example, format)
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
