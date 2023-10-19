defmodule Labex.Measurement do
  defmacro __using__(_opts) do
    quote do
      import Labex.Measurement
      @instruments %{}
      @before_compile unquote(__MODULE__)

      def start_instruments() do
        for {name, {_model, impl, opts}} <- instruments() do
          Labex.InstrumentManager.start_instrument(name, impl, opts)
        end
      end

      def read(name, cmd, args) do
        {model, _inst, _opts} = Map.get(instruments(), name)
        Labex.InstrumentManager.read(name, {model, cmd, args})
      end

      def write(name, cmd, args) do
        {model, _inst, _opts} = Map.get(instruments(), name)
        Labex.InstrumentManager.write(name, {model, cmd, args})
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def instruments() do
        @instruments
      end
    end
  end

  @spec def_inst(atom(), module(), module(), any()) :: Macro.t()
  defmacro def_inst(name, model, inst_impl, opts) do
    quote do
      @instruments Map.put(
                     @instruments,
                     unquote(name),
                     {unquote(model), unquote(inst_impl), unquote(opts)}
                   )
    end
  end
end
