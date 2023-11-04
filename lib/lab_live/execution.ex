defmodule LabLive.Execution do
  alias LabLive.Execution.Worker

  defmacro branch(exp, branch) do
    exp_str = quote(do: unquote(exp)) |> Macro.to_string()

    quote do
      [f: fn -> unquote(exp) end, str: unquote(exp_str), branch: unquote(branch)]
    end
  end

  @spec set(diagram :: Diagram.diagram()) :: :ok
  def set(diagram) do
    Worker.set_diagram(diagram)
  end

  def buttons() do
    start = Kino.Control.button("Start")
    pause = Kino.Control.button("Pause")
    Kino.Layout.grid([start, pause]) |> Kino.render()

    stream = Kino.Control.tagged_stream(start: start, pause: pause)

    Kino.listen(stream, fn
      {:start, _event} -> Worker.start_run()
      {:pause, _event} -> Worker.pause()
    end)
  end
end
