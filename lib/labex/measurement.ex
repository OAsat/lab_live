defmodule Labex.Measurement do
  defmacro __using__(_opts) do
    quote do
      import Labex.Measurement
      Module.register_attribute(__MODULE__, :instruments, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def instruments() do
        @instruments
      end
    end
  end

  defmacro instrument(name, model, impl) do
    quote do
      @instruments {unquote(name), unquote(model), unquote(impl)}
    end
  end

  # def start_instruments
end
