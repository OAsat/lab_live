defmodule LabLive.Instrument.Impl.Demo do
  @moduledoc """
  Demo instrument.
  """
  alias LabLive.Instrument.Impl
  @behaviour Impl

  @impl Impl
  def init(opts) do
    opts[:dummy]
  end

  @impl Impl
  def read(message, map) do
    case map[message] do
      nil -> {"#{:rand.uniform()}", nil}
      f when is_function(f, 0) -> {f.(), nil}
      answer -> {answer, nil}
    end
  end

  @impl Impl
  def after_reply(nil, _map) do
    nil
  end

  @impl Impl
  def write(_message, _map) do
    :ok
  end

  @impl Impl
  def terminate(_reason, _map) do
    nil
  end
end
