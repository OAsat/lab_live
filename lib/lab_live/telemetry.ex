defmodule LabLive.Telemetry do
  require Logger

  def handle_instrument(
        [:lab_live, :instrument, event],
        %{query: query, answer: answer, state: %LabLive.Instrument.Port.State{opts: opts}},
        _meta,
        _config
      ) do
    name = if opts[:key] == nil, do: opts[:name], else: opts[:key]

    Logger.info(
      "Instrument|#{event}|#{inspect(name)}| query:#{inspect(query)}, answer:#{inspect(answer)}"
    )
  end
end
