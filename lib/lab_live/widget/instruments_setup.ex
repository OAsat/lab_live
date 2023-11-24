defmodule LabLive.Widget.InstrumentsSetup do
  use Kino.JS, assets_path: "lib/assets/instruments_setup"
  use Kino.JS.Live
  use Kino.SmartCell, name: "LabLive.Instruments"
  # alias LabLive.Model
  # alias LabLive.Model.Format

  @impl true
  def init(attrs, ctx) do
    specs = attrs["specs"] || []
    {:ok, assign(ctx, specs: specs)}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{specs: ctx.assigns.specs}
    {:ok, payload, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    %{"specs" => ctx.assigns.specs}
  end

  @impl true
  def to_source(attrs) do
    quote do
      unquote(attrs["specs"])
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  @impl true
  def handle_event("add_instrument", _payload, ctx) do
    new_spec = %{
      name: "",
      sleep_after_reply: "0",
      model: "",
      selected_type: "Dummy",
      dummy: %{if_random: "False"},
      pyvisa: %{address: ""},
      tcp: %{address: "", port: ""}
    }

    specs = ctx.assigns.specs ++ [new_spec]
    ctx = assign(ctx, specs: specs)
    broadcast_event(ctx, "update_specs", specs)
    {:noreply, ctx}
  end

  @impl true
  def handle_event("remove_instrument", %{"idx" => index}, ctx) do
    updated_specs = if index, do: List.delete_at(ctx.assigns.specs, index), else: []
    ctx = assign(ctx, specs: updated_specs)
    broadcast_event(ctx, "update_specs", updated_specs)
    {:noreply, ctx}
  end

  @impl true
  def handle_event("form_changed", %{"specs" => specs}, ctx) do
    ctx = assign(ctx, specs: specs)
    broadcast_event(ctx, "update_specs", specs)
    {:noreply, ctx}
  end
end
