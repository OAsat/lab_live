defmodule LabLive.Connection.Method do
  @callback init(opts :: any()) :: resource :: any()
  @callback read(message :: binary(), resource :: any()) :: answer :: binary()
  @callback write(message :: binary(), resource :: any()) :: :ok
  @callback terminate(reason :: any(), resource :: any()) :: :ok
end
