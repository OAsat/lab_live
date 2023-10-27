defmodule LabLive.Instrument.Dummy do
  @moduledoc """
  Dummy instrument.

      iex> alias LabLive.Instrument.Dummy
      iex> expected_map = %{"read" => "answer", "write" => nil}
      iex> {:ok, pid} = LabLive.Instrument.start_link({:dummy_test, Dummy, map: expected_map})
      iex> LabLive.Instrument.read(pid, "read")
      "answer"
      iex> LabLive.Instrument.write(pid, "write")
      :ok
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
