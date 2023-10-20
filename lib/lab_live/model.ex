defmodule LabLive.Model do
  alias LabLive.Format

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :write_format, accumulate: true)
      Module.register_attribute(__MODULE__, :read_format, accumulate: true)

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
      @read_format {unquote(name), {unquote(query_format), unquote(answer_format)}}
      def read(unquote(name), opts) do
        query =
          unquote(query_format)
          |> Format.format(opts)
          |> with_write_term()

        answer_format = unquote(answer_format) |> with_read_term()

        parser = fn answer ->
          Format.parse(answer, answer_format)
        end

        {query, parser}
      end
    end
  end

  @spec def_write(name :: atom(), String.t()) :: Macro.t()
  defmacro def_write(name, query_format) do
    quote do
      @write_format {unquote(name), unquote(query_format)}
      def write(unquote(name), opts) do
        unquote(query_format)
        |> Format.format(opts)
        |> with_write_term()
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

      def write_formats() do
        @write_format
      end

      def read_formats() do
        @read_format
      end
    end
  end
end
