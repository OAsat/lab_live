defmodule LabLive.Widget.InstrumentsSetup do
  use Kino.JS, assets_path: "lib/assets/instruments_setup"
  use Kino.JS.Live
  use Kino.SmartCell, name: "LabLive/Instruments"
  alias LabLive.Model

  @impl true
  def init(attrs, ctx) do
    specs = attrs["specs"] || []
    assign_to = attrs["assign_to"] || ""
    {:ok, assign(ctx, specs: specs, assign_to: assign_to)}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{specs: ctx.assigns.specs, assign_to: ctx.assigns.assign_to}
    {:ok, payload, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    %{"specs" => ctx.assigns.specs, "assign_to" => ctx.assigns.assign_to}
  end

  @impl true
  def to_source(attrs) do
    case attrs["assign_to"] do
      "" ->
        quote do
          unquote(attrs["specs"])
          |> LabLive.Widget.InstrumentsSetup.convert_attrs_specs(__ENV__)
          |> LabLive.Instrument.start_instruments()
        end

      assign_to ->
        quote do
          unquote({String.to_atom(assign_to), [], nil}) =
            unquote(attrs["specs"])
            |> LabLive.Widget.InstrumentsSetup.convert_attrs_specs(__ENV__)

          LabLive.Instrument.start_instruments(unquote({String.to_atom(assign_to), [], nil}))
        end
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
  def handle_event("form_changed", %{"specs" => specs, "assign_to" => assign_to}, ctx) do
    ctx = assign(ctx, specs: specs, assign_to: assign_to)
    broadcast_event(ctx, "update_specs", specs)
    {:noreply, ctx}
  end

  def convert_attrs_specs(specs, env \\ []) do
    for spec <- specs do
      key = String.to_atom(spec["name"])
      model = get_model(spec, env)

      {key,
       %{
         name: key,
         sleep_after_reply: get_sleep_after_reply(spec),
         model: model,
         selected_type: get_selected_type(spec),
         dummy: get_dummy_spec(spec, model),
         pyvisa: get_pyvisa_spec(spec),
         tcp: get_tcp_spec(spec)
       }}
    end
  end

  defp parse_int_or_nil(str) do
    case Integer.parse(str) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp get_sleep_after_reply(spec) do
    parse_int_or_nil(spec["sleep_after_reply"])
  end

  defp get_model(spec, env) do
    case spec["model"] do
      "" ->
        nil

      exp ->
        with {result, _} <- Code.eval_string(exp, [], env),
             true <- is_map(result) do
          Model.from_map(result)
        else
          _ -> nil
        end
    end
  end

  defp get_selected_type(spec) do
    case spec["selected_type"] do
      "Dummy" -> :dummy
      "PyVISA" -> :pyvisa
      "TCP/IP" -> :tcp
    end
  end

  defp get_dummy_spec(spec, model) do
    %{random: spec["dummy"]["if_random"] == "True", model: model}
  end

  defp get_pyvisa_spec(spec) do
    %{address: spec["pyvisa"]["address"]}
  end

  defp get_tcp_spec(spec) do
    %{port: parse_int_or_nil(spec["tcp"]["port"]), address: convert_tcp_address(spec["tcp"])}
  end

  defp convert_tcp_address(tcp_spec) do
    address =
      String.split(tcp_spec["address"], ".")
      |> Enum.map(&parse_int_or_nil(&1))
      |> Enum.reject(&is_nil(&1))

    case length(address) do
      4 -> address
      _ -> nil
    end
  end
end
