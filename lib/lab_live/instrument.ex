defmodule LabLive.Instrument do
  @moduledoc """
  Functions to handle instruments.

      iex> alias LabLive.Instrument
      iex> alias LabLive.Instrument.Impl.Dummy
      iex> {:ok, _pid} = Instrument.start(:inst1, model: Lakeshore350, type: Dummy, dummy: Lakeshore350.dummy())
      iex> Instrument.read(:inst1, "SETP? 2\\n")
      "1.0\\r\\n"
      iex> Instrument.read(:inst1, :setp, channel: 2)
      %{kelvin: 1.0}
      iex> Instrument.read_joined(:inst1, sensor: [channel: "A"], sensor: [channel: "C"], heater: [channel: 2])
      [sensor: %{ohm: 1200.0}, sensor: %{ohm: 0.23}, heater: %{percentage: 56.7}]

  Starting multiple instruments:
      iex> alias LabLive.Instrument
      iex> alias LabLive.Instrument.Impl.Dummy
      iex> instruments = [
      ...>     inst2: [type: Dummy, dummy: %{}],
      ...>     inst3: [type: Dummy, dummy: %{}]
      ...>   ]
      iex> %{inst2: {:ok, _}, inst3: {:ok, _}} = Instrument.start(instruments)
  """
  alias LabLive.Instrument.PortManager
  alias LabLive.Instrument.Port

  def start(instruments) when is_list(instruments) or is_map(instruments) do
    PortManager.start_instrument(instruments)
  end

  def start(instrument, opts \\ []) when is_atom(instrument) and is_list(opts) do
    PortManager.start_instrument(instrument, opts)
  end

  def read(key, query) when is_binary(query) do
    PortManager.pid(key) |> Port.read(query)
  end

  def read(key, query_key, opts \\ []) when is_atom(query_key) and is_list(opts) do
    {pid, model} = PortManager.info(key)
    Port.read(pid, model, query_key, opts)
  end

  def read_joined(key, query_keys_and_opts) when is_list(query_keys_and_opts) do
    {pid, model} = PortManager.info(key)
    Port.read_joined(pid, model, query_keys_and_opts)
  end

  def write(key, query) when is_binary(query) do
    PortManager.pid(key) |> Port.write(query)
  end

  def write(key, query_key, opts \\ []) when is_atom(query_key) and is_list(opts) do
    {pid, model} = PortManager.info(key)
    Port.write(pid, model, query_key, opts)
  end

  def write_joined(key, query_keys_and_opts) when is_list(query_keys_and_opts) do
    {pid, model} = PortManager.info(key)
    Port.write_joined(pid, model, query_keys_and_opts)
  end

  def render_controller() do
    inst_labels =
      PortManager.keys_and_pids()
      |> Enum.map(fn {key, _pid} -> {key, "#{key}"} end)

    form =
      Kino.Control.form(
        [
          inst: Kino.Input.select("Instrument", inst_labels),
          query: Kino.Input.text("Query"),
          method: Kino.Input.select("Read/Write", read: "Read", write: "Write")
        ],
        submit: "Send"
      )

    Kino.listen(
      form,
      fn %{data: %{inst: inst, query: query, method: method}} ->
        case method do
          :read -> read(inst, query <> "\n")
          :write -> write(inst, query <> "\n")
        end
      end
    )

    form
  end
end
