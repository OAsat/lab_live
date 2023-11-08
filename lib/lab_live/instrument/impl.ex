defmodule LabLive.Instrument.Impl do
  @callback init(opts :: any()) :: resource :: any()
  @callback read(message :: binary(), resource :: any()) :: {answer :: binary(), info :: any()}
  @callback after_reply(info :: any(), resource :: any()) :: :ok
  @callback write(message :: binary(), resource :: any()) :: :ok
  @callback terminate(reason :: any(), resource :: any()) :: :ok
end
