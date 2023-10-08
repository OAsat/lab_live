defmodule Labex.Measurement do
  defmacro __using__(_opts) do
    quote do
      import Labex.Measurement
      @instruments %{}
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

  defmacro instrument(name, model, impl, params) do
    child_spec = {impl, {name, params}}

    quote do
      @instruments {unquote(model), unquote(child_spec)}
    end
  end
end
