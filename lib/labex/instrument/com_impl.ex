defmodule Labex.Instrument.ComImpl do
  @callback init(opts :: tuple()) :: any
  @callback write(message :: String.t(), opts :: tuple()) :: :ok | {:error, any()}
  @callback query(message :: String.t(), opts:: tuple()) :: {:ok, String.t()} | {:error, any()}
end
