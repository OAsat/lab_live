defmodule LabLive.ModelTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Model
  import Test.Support.QueryStream

  doctest Model

  @lakeshore_json "test/support/models/lakeshore350.model.json"
  @lakeshore_toml "test/support/models/lakeshore350.model.toml"

  describe "loading LakeShore350 sample files" do
    test "from_json_file/1" do
      assert Lakeshore350.model() == Model.from_json_file(@lakeshore_json)
    end

    test "from_toml_file/1" do
      assert Lakeshore350.model() == Model.from_toml_file(@lakeshore_toml)
    end
  end

  describe "loading mercury sample files" do
    test "toml is valid" do
      file = "test/support/models/oxford_mercury_itc.model.toml"
      assert %Model{} = Model.from_toml_file(file)
    end
  end

  describe "format_input/3" do
    test "returns error with unknown key" do
      model = %Model{}
      assert {:error, :key_not_found} == Model.format_input(model, :unknown, %{a: 1})
    end

    test "returns formatted string" do
      check all(
              {format, expected, params} <- input_stream(),
              key <- atom(:alphanumeric)
            ) do
        model = %Model{query: %{key => %{input: format}}}
        assert expected <> model.character.input_term == Model.format_input(model, key, params)
      end
    end
  end

  describe "format_joined_input/2" do
    test "returns formatted string" do
      check all(input_map <- map_of(atom(:alphanumeric), input_stream())) do
        {formats, queries, params} =
          Enum.reduce(
            input_map,
            {%{}, [], []},
            fn {key, {format, query, param}}, {formats, queries, params} ->
              {
                Map.put(formats, key, %{input: format}),
                queries ++ [query],
                params ++ [{key, param}]
              }
            end
          )

        model = %Model{query: formats}
        expected = Enum.join(queries, model.character.joiner) <> model.character.input_term

        assert expected == Model.format_joined_input(model, params)
      end
    end
  end
end
