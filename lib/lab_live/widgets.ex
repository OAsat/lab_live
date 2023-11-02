defmodule LabLive.Widgets do
  use GenServer
  alias LabLive.PropertyManager

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
      LabLive.Diagram.to_mermaid_markdown(diagram, running: status)
    )

    {:noreply, state}
  end

  def update_diagram(exec_state) do
    GenServer.cast(__MODULE__, {:update_diagram, exec_state})
  end

  def render_diagram() do
    GenServer.cast(__MODULE__, :render_diagram)
  end

  def render_exec_buttons() do
    start = Kino.Control.button("Start")
    pause = Kino.Control.button("Pause")
    Kino.Layout.grid([start, pause]) |> Kino.render()

    stream = Kino.Control.tagged_stream(start: start, pause: pause)

    Kino.listen(stream, fn
      {:start, _event} -> LabLive.Execution.start()
      {:pause, _event} -> LabLive.Execution.pause()
    end)
  end

  def render_props(props) do
    content =
      for {key, opts} <- props do
        label = Keyword.get(opts, :label, to_string(key))
        "|#{key}|#{label}|#{PropertyManager.get(key)}|"
      end
      |> Enum.join("\n")

    Kino.Markdown.new("|key|label|value|\n|--|--|--|\n" <> content)
  end

  def monitor_props(props, interval \\ 100) do
    Kino.animate(interval, fn _ -> render_props(props) end)
  end
end
