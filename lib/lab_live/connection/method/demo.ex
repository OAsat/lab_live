defmodule LabLive.Instrument.Method.Demo do
  @moduledoc """
  Demo instrument.
  """
  alias LabLive.Connection.Method
  @behaviour Method

  @type opt() :: {:dummy, any()}
  @type opts() :: [opt()]

  @impl Method
  def init(opts) do
    opts[:dummy]
  end

  @impl Method
  def read(message, map) do
    case map[message] do
      nil -> {"#{:rand.uniform()}", nil}
      f when is_function(f, 0) -> {f.(), nil}
      answer -> {answer, nil}
    end
  end

  @impl Method
  def after_reply(nil, _map) do
    :ok
  end

  @impl Method
  def write(_message, _map) do
    :ok
  end

  @impl Method
  def terminate(_reason, _map) do
    :ok
  end
end
