defmodule ModelTest do
  use ExUnit.Case
  doctest Labex.Instrument.Model

  test "def model" do
    defmodule SampleModel do
      use Labex.Instrument.Model

      @impl Labex.Instrument.Model
      def read(:kelvin), do: {"KRDG? ~s", "~f"}
      @impl Labex.Instrument.Model
      def write(:setp), do: "SETP ~s, ~p"
    end

    defmodule MyBehaviour do
      @callback foobar(foo_arg :: any()) :: any()

      assert SampleModel.read(:kelvin) == {"KRDG? ~s", "~f"}
      assert SampleModel.write(:setp) == "SETP ~s, ~p"
      # assert_raise(
      #   FunctionClauseError,
      #   "Function read(:empty) is not implemented.",
      #   fn -> SampleModel.read(:empty) end
      # )
    end
  end
end
