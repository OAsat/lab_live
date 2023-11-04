defmodule LabLive.Instrument.Impl do
  @callback init(opts :: any()) :: resource :: any()
  @callback read(message :: binary(), resource :: any()) :: {answer :: binary(), info :: any()}
  @callback after_reply(info :: any(), resource :: any()) :: any()
  @callback write(message :: binary(), resource :: any()) :: :ok
end
