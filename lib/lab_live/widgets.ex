defmodule LabLive.Widgets do
  use GenServer

  def start_under_kino() do
    Kino.start_child(__MODULE__)
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl GenServer
  def init(:ok) do
    diagram_frame = Kino.Frame.new()
    {:ok, %{diagram_frame: diagram_frame}}
  end

  @impl GenServer
  def handle_cast(:render_diagram, state) do
    state.diagram_frame |> Kino.render()
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:update_diagram, exec_state}, state) do
    diagram = exec_state.diagram
    status = exec_state.status

    Kino.Frame.render(
      state.diagram_frame,
      LabLive.Execution.Diagram.to_mermaid_markdown(diagram, running: status)
    )

    {:noreply, state}
  end

  def update_diagram(exec_state) do
    GenServer.cast(__MODULE__, {:update_diagram, exec_state})
  end

  def render_diagram() do
    GenServer.cast(__MODULE__, :render_diagram)
  end
end
