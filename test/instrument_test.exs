defmodule InstrumentTest do
  use ExUnit.Case
  doctest Labex.Instrument

  test "impl" do
    defmodule DummyInstrument do
      alias Labex.Instrument.ComImpl
      @behaviour ComImpl

      @impl ComImpl
      def init(opts) do
        opts
      end

      @impl ComImpl
      def query(message, opts) do
        {:ok, message}
      end

      @impl ComImpl
      def write(message, opts) do
        {:ok, message}
      end
    end

    defmodule LabexTest.Instr do
      use Labex.Instrument, impl: DummyInstrument
    end

    {:ok, _pid} = LabexTest.Instr.start_link({})
  end

end
