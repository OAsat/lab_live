defmodule LabLive.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LabLive.Instruments,
      LabLive.Variables
    ]

    :ok =
      :telemetry.attach_many(
        "lab_live read handler",
        [
          [:lab_live, :instrument, :read],
          [:lab_live, :instrument, :write]
        ],
        &LabLive.Telemetry.handle_instrument/4,
        nil
      )

    opts = [strategy: :one_for_one, name: LabLive.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
