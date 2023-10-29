defmodule LabLive.Instrument.Dummy do
  @moduledoc """
  Dummy instrument.
  """
  alias LabLive.Instrument

  @behaviour Instrument

  @impl Instrument
  def init(opts) do
    map = Keyword.get(opts, :map)
    map
  end

  @impl Instrument
  def read(message, map) do
    %{^message => answer} = map
    {answer, nil}
  end

  @impl Instrument
  def after_reply(nil, _map) do
    nil
  end

  @impl Instrument
  def write(message, map) do
    if not Map.has_key?(map, message) do
      raise "Write message #{message} not expected."
    else
      :ok
    end
  end
end
