defmodule Labex.Measurement do
  defmacro __using__(_opts) do
    quote do
      import Labex.Measurement
      @instruments %{}
      # Module.register_attribute(__MODULE__, :instruments, accumulate: true)
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
      @instruments Map.put(
                     @instruments,
                     unquote(name),
                     {unquote(model), unquote(child_spec)}
                   )
    end
  end

  def start_instruments() do
  end

  def start_instrument_manager() do
    children = [
      {DynamicSupervisor, name: Labex.InstrumentSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: Labex.InstrumentRegistry}
    ]

    Supervisor.start_link(children, strategy: :one_for_all, name: Labex.InstrumentManager)
  end
end
