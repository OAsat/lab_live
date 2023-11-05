defmodule LabLive.Plot do
  defstruct [:widgets, :frame]

  use GenServer
  alias LabLive.Data

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(nil) do
    {:ok, %__MODULE__{widgets: [], frame: Kino.Frame.new()}}
  end

  @impl GenServer
  def handle_cast({:init_plot, axes_list}, %__MODULE__{frame: frame} = state) do
    widgets =
      for [axes | opts] <- axes_list do
        {axes, new_plot(axes, opts)}
      end

    Kino.Frame.render(frame, widgets |> Keyword.values() |> Kino.Layout.grid())

    {:noreply, %__MODULE__{state | widgets: widgets}}
  end

  @impl GenServer
  def handle_cast(:update, %__MODULE__{widgets: widgets} = state) do
    for {{x_key, y_key}, widget} <- widgets do
      :ok = Kino.VegaLite.push(widget, %{x_key => Data.get(x_key), y_key => Data.get(y_key)})
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:render, _from, state) do
    {:reply, state.frame, state}
  end

  defp new_plot({x_key, y_key}, opts) do
    VegaLite.new(opts)
    |> VegaLite.mark(:point)
    |> VegaLite.encode_field(:x, to_string(x_key), type: :quantitative, title: Data.label(x_key))
    |> VegaLite.encode_field(:y, to_string(y_key), type: :quantitative, title: Data.label(y_key))
    |> Kino.VegaLite.new()
  end

  def init_plot(axes_list) do
    GenServer.cast(__MODULE__, {:init_plot, axes_list})
  end

  def update() do
    GenServer.cast(__MODULE__, :update)
  end

  def render() do
    GenServer.call(__MODULE__, :render)
  end
end
