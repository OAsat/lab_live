defmodule LabLive.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(LabLive.Widget.InstrumentsSetup)

    children = [
      LabLive.ConnectionManager,
      LabLive.StorageManager,
      LabLive.Execution.Supervisor,
      {DynamicSupervisor, strategy: :one_for_one, name: LabLive.Data.Supervisor}
    ]

    if Application.get_env(:lab_live, :logging, false) do
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
    end

    opts = [strategy: :one_for_one, name: LabLive.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
