defmodule Labex.Instrument.Impl do
  @callback write(message :: String.t(), opts :: any()) :: any()
  @callback read(message :: String.t(), opts :: any()) :: any()
end
