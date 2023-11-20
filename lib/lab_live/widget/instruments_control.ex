defmodule LabLive.Widget.InstrumentsControl do
  use Kino.JS, assets_path: "lib/assets/instruments_control"
  use Kino.JS.Live
  alias LabLive.ConnectionManager
  alias LabLive.Model
  alias LabLive.Model.Format

  @impl true
  def init(nil, ctx) do
    ctx =
      assign(ctx,
        models: models(),
        instrument: "",
        query: ""
      )

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      models: ctx.assigns.models,
      instrument: ctx.assigns.instrument,
      query: ctx.assigns.query
    }

    {:ok, payload, ctx}
  end

  def new() do
    Kino.JS.Live.new(__MODULE__, nil)
  end

  defp models() do
    ConnectionManager.keys_and_pids()
    |> Enum.map(fn {key, _pid} ->
      %{model: model} = ConnectionManager.info(key)
      {key, model_to_map(model)}
    end)
    |> Enum.into(%{})
  end

  defp model_to_map(%Model{} = model) do
    for {key, %{input: input}} <- model.query do
      params = Format.extract_keys_and_types(input) |> Keyword.keys()
      {key, params}
    end
    |> Enum.into(%{})
  end
end
