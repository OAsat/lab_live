defmodule LabLive.Widget.InstrumentsControl do
  use Kino.JS, assets_path: "lib/assets/instruments_control"
  use Kino.JS.Live
  alias LabLive.ConnectionManager
  alias LabLive.Model
  alias LabLive.Model.Format
  alias LabLive.Instrument

  @impl true
  def init(nil, ctx) do
    ctx =
      assign(ctx,
        models: models(),
        instrument: "",
        query_key: "",
        answer: ""
      )

    {:ok, ctx}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      models: ctx.assigns.models,
      instrument: ctx.assigns.instrument,
      query_key: ctx.assigns.query_key,
      answer: ctx.assigns.answer
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("send_query", %{"instrument" => ""}, ctx) do
    {:noreply, ctx}
  end

  def handle_event("send_query", %{"query_key" => ""}, ctx) do
    {:noreply, ctx}
  end

  def handle_event(
        "send_query",
        %{"instrument" => instrument, "query_key" => query_key, "params" => params},
        ctx
      ) do
    param_values = for {key, %{value: value}} <- params, do: {:"#{key}", value}
    answer = Instrument.query(:"#{instrument}", :"#{query_key}", param_values) |> Kernel.inspect()
    ctx = assign(ctx, answer: answer)
    broadcast_event(ctx, "update_answer", answer)
    {:noreply, ctx}
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
      {key, input_format_to_map_list(input)}
    end
    |> Enum.into(%{})
  end

  defp input_format_to_map_list(input) do
    Format.extract_keys_and_types(input)
    |> Enum.map(fn {key, type} -> %{key: key, type: type, value: ""} end)
  end
end
