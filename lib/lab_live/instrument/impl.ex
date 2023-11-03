defmodule LabLive.Instrument.Impl do
  @callback init(opts :: any()) :: state :: any()
  @callback read(message :: binary(), state :: any()) :: {answer :: binary(), info :: any()}
  @callback after_reply(info :: any(), state :: any()) :: any()
  @callback write(message :: binary(), state :: any()) :: :ok
end
