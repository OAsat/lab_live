defmodule LabLive.Telemetry do
  require Logger

  def handle_instrument(
        [:lab_live, :instrument, event],
        %{query: query, answer: answer, state: %LabLive.Connection.State{name: name}},
        _meta,
        _config
      ) do
    Logger.info(
      "Instrument|#{event}|#{inspect(name)}| query:#{inspect(query)}, answer:#{inspect(answer)}"
    )
  end
end
