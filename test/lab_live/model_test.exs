defmodule LabLive.ModelTest do
  use ExUnit.Case
  use ExUnitProperties
  alias LabLive.Model
  import Test.Support.Format

  doctest Model

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
        expected == Model.format_input(model, key, params)
      end
    end
  end
end
