defmodule LabLive.Telemetry do
  require Logger

  def handle_instrument(
        [:lab_live, :instrument, :read],
        %{message: message, answer: answer},
        %{name: name},
        _config
      ) do
    Logger.info(
      "read inst #{inspect(name)}. message:#{inspect(message)}, answer:#{inspect(answer)}"
    )
  end

  def handle_instrument(
        [:lab_live, :instrument, :write],
        %{message: message, answer: nil},
        %{name: name},
        _config
      ) do
    Logger.info("write inst #{inspect(name)}. message:#{inspect(message)}")
  end
end
