defmodule LabLive.Execution do
  alias LabLive.Execution.Worker

  defmacro branch(exp, branch) do
    exp_str = quote(do: unquote(exp)) |> Macro.to_string()

    quote do
      [f: fn -> unquote(exp) end, str: unquote(exp_str), branch: unquote(branch)]
    end
  end

  @spec set(diagram :: LabLive.Execution.Diagram.diagram()) :: :ok
  def set(diagram) do
    Worker.set_diagram(diagram)
  end

  def buttons() do
    start = Kino.Control.button("Start")
    pause = Kino.Control.button("Pause")
    reset = Kino.Control.button("Reset")
    Kino.Layout.grid([start, pause, reset]) |> Kino.render()

    stream = Kino.Control.tagged_stream(start: start, pause: pause, reset: reset)

    Kino.listen(stream, fn
      {:start, _event} -> Worker.start_run()
      {:pause, _event} -> Worker.pause()
      {:reset, _event} -> Worker.reset()
    end)
  end

  def monitor(interval \\ 100) do
    Kino.animate(
      interval,
      fn _ ->
        Worker.get_state().status
        |> inspect()
        |> Kino.Text.new()
      end
    )
  end

  @spec render(LabLive.Execution.Diagram.diagram()) :: Kino.Markdown.t()
  def render(diagram) do
    LabLive.Execution.Diagram.to_mermaid_markdown(diagram) |> Kino.render()
  end
end
