defmodule LabLive do
  @moduledoc """
  Documentation for `LabLive`.
  """
  alias LabLive.Execution.Worker

  def run_many(module, functions) do
    for function <- functions do
      Task.async(module, function, [])
    end
    |> Task.await_many(:infinity)
  end

  @doc """
  Returns the list of labels of the data.

      iex> LabLive.labels([a: [label: "A"], b: [label: "B"]])
      [a: "A", b: "B"]
  """
  def labels(list) when is_list(list) do
    for {key, specs} <- list do
      {key, specs[:label] || "#{key}"}
    end
  end

  def render_worker(worker \\ LabLive.Execution.Worker) do
    %Worker.State{stack: stack, run?: run?} = Worker.get_state(worker, :infinity)

    display_str =
      case stack do
        [] -> "finish"
        [head | _] -> inspect(head)
      end

    Kino.Text.new("[running?: #{run?}] #{display_str}")
  end

  def monitor_worker(worker \\ LabLive.Execution.Worker, interval \\ 200) do
    Kino.animate(interval, fn _ -> render_worker(worker) end)
  end

  def render_buttons() do
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
end
