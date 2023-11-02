defmodule LabLive.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LabLive.Instruments,
      LabLive.PropertyManager,
      LabLive.Execution,
      LabLive.Widgets
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

    :ok =
      :telemetry.attach(
        "lab_live execution handler",
        [:lab_live, :execution, :update_status],
        &LabLive.Telemetry.update_widget/4,
        nil
      )

    opts = [strategy: :one_for_one, name: LabLive.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
