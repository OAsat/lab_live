defmodule Labex.Instrument.Model do
  alias Labex.Utils.Format

  defmacro __using__(_opts) do
    quote do
      import Labex.Instrument.Model
    end
  end

  defmacro def_read(key, query_format, answer_format) do
    quote do
      def read(unquote(key), params, {impl_module, inst_name}) do
        unquote(query_format)
        |> Format.format_query(params)
        |> impl_module.read(inst_name)
        |> Format.parse_answer(unquote(answer_format))
      end
    end
  end

  defmacro def_write(key, query_format) do
    quote do
      def write(unquote(key), params, {impl_module, inst_name}) do
        unquote(query_format)
        |> Format.format_query(params)
        |> impl_module.write(inst_name)
      end
    end
  end
end
