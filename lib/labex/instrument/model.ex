defmodule Labex.Instrument.Model do
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      @read_termination "\n"
      @write_termination "\n"

      def with_read_term(fmt) do
        fmt <> read_termination()
      end

      def with_write_term(fmt) do
        fmt <> write_termination()
      end
    end
  end

  @spec def_read(name :: atom(), String.t(), String.t()) :: Macro.t()
  defmacro def_read(name, query_format, answer_format) do
    quote do
      def read(unquote(name)) do
        {unquote(query_format) |> with_read_term(), unquote(answer_format) |> with_read_term()}
      end
    end
  end

  @spec def_write(name :: atom(), String.t()) :: Macro.t()
  defmacro def_write(name, query_format) do
    quote do
      def write(unquote(name)) do
        unquote(query_format) |> with_read_term()
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def read_termination() do
        @read_termination
      end

      def write_termination() do
        @write_termination
      end
    end
  end
end
