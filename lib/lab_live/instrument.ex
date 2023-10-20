defmodule LabLive.Instrument do
  @callback start_link({name :: GenServer.name(), opts :: any()}) :: any()
  @callback write(pid :: pid(), query :: String.t(), opts :: any()) :: any()
  @callback read(pid :: pid(), query :: String.t(), opts :: any()) :: String.t()
end
