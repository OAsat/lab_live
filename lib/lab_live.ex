defmodule LabLive do
  @moduledoc """
  Documentation for `LabLive`.
  """
  alias LabLive.Data
  alias LabLive.Execution.Worker

  @type on_start_data() :: {:ok, pid()} | {:override, pid()} | {:error, term()}
  @type many_data() :: %{Data.name() => Data.data_specs()} | [{Data.name(), Data.data_specs()}]

  def run_many(module, functions) do
    for function <- functions do
      Task.async(module, function, [])
    end
    |> Task.await_many(:infinity)
  end

  def value(id) do
    Data.value(id)
  end

  def get_value_many(list) when is_list(list) do
    for id <- list do
      {id, value(id)}
    end
  end

  def get(id) do
    Data.get(id)
  end

  def get_many(list) when is_list(list) do
    for id <- list do
      {id, get(id)}
    end
  end

  def update(id) do
    Data.update(id)
  end

  def update(value, id) do
    Data.update(value, id)
  end

  def update_many(list) when is_list(list) do
    for {id, value} <- list do
      update(value, id)
    end
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

  @spec start_many_data(many_data(), module()) :: [{Data.name(), on_start_data()}]
  def start_many_data(many_data, supervisor \\ LabLive.Data.Supervisor) do
    for {name, data_specs} <- many_data do
      {name, start_data(name, data_specs, supervisor)}
    end
  end

  @spec start_data(Data.name(), Data.data_specs(), module()) :: on_start_data()
  def start_data(name, data_specs, supervisor \\ LabLive.Data.Supervisor) do
    case DynamicSupervisor.start_child(supervisor, {LabLive.Data, [{:name, name} | data_specs]}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        :ok = data_specs[:init] |> LabLive.Data.override(pid)
        {:override, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec data_to_markdown(many_data()) :: String.t()
  def data_to_markdown(many_data) do
    content =
      many_data
      |> Enum.filter(fn {_, specs} -> Keyword.get(specs, :visible?, true) end)
      |> Enum.map(fn {name, specs} ->
        value = LabLive.Data.get(name)

        value_str =
          case String.Chars.impl_for(value) do
            nil -> inspect(value)
            _ -> to_string(value)
          end

        "|#{name}|#{specs[:label]}|#{value_str}|"
      end)
      |> Enum.join("\n")

    "|key|label|value|\n|--|--|--|\n" <> content <> "\n"
  end

  @spec render_data(many_data()) :: Kino.Markdown.t()
  def render_data(many_data) do
    data_to_markdown(many_data) |> Kino.Markdown.new()
  end

  @spec monitor_data(many_data(), pos_integer()) :: Kino.nothing()
  def monitor_data(many_data, interval \\ 200) do
    Kino.animate(interval, fn _ -> render_data(many_data) end)
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
