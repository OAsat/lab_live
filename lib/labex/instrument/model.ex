defmodule Labex.Instrument.Model do
  alias Labex.Utils.Format

  defmacro __using__(_opts) do
    quote do
      import Labex.Instrument.Model
    end
  end

  defmacro def_read(key, query_format, answer_format) do
    quote do
      def read(unquote(key), params, impl_module) do
        unquote(query_format)
        |> Format.format_query(params)
        |> impl_module.query(unquote(key))
        |> Format.parse_answer(unquote(answer_format))
      end
    end
  end
end
