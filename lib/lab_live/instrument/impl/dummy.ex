defmodule LabLive.Instrument.Impl.Dummy do
  @moduledoc """
  Dummy instrument.
  """
  alias LabLive.Instrument.Impl
  @behaviour Impl

  @impl Impl
  def init(opts) do
    map = Keyword.get(opts, :map)
    map
  end

  @impl Impl
  def read(message, map) do
    %{^message => answer} = map
    {answer, nil}
  end

  @impl Impl
  def after_reply(nil, _map) do
    nil
  end

  @impl Impl
  def write(message, map) do
    if not Map.has_key?(map, message) do
      raise "Write message #{message} not expected."
    else
      :ok
    end
  end
end
