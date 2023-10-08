defmodule Labex.Instrument.Model do
  @callback read(key :: atom()) :: {query_format :: String.t(), answer_format :: String.t()}
  @callback write(key :: atom()) :: query_format :: String.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      def read(_), do: nil
      def write(_), do: nil

      defoverridable read: 1, write: 1
    end
  end
end
