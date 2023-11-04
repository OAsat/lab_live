defmodule LabLive.Instrument.Port do
  @moduledoc """
  Sever to communicate with measurement instrument.

  See `LabLive.Instrument.Impl.Dummy` for examples.

  ### Example
  (For the definition of `Lakeshore350.dummy/0` and `Lakeshore350`, see `LabLive.Instrument.Model`.)
      iex> alias LabLive.Instrument.Port
      iex> map = Lakeshore350.dummy()
      iex> {:ok, pid} = Port.start_link([name: :ls350, type: LabLive.Instrument.Impl.Dummy, map: map, sleep_after: 1])
      iex> Port.read(pid, "SETP? 2\\n")
      "1.0\\r\\n"
      iex> Port.read(pid, Lakeshore350, :ramp, channel: 2)
      %{onoff: 1, kpermin: 0.2}
      iex> Port.read_joined(pid, Lakeshore350, sensor: [channel: "A"], sensor: [channel: "C"], heater: [channel: 2])
      [sensor: %{ohm: 1200.0}, sensor: %{ohm: 0.23}, heater: %{percentage: 56.7}]
  """
  use GenServer
  alias LabLive.Instrument.Model

  defmodule State do
    @moduledoc false
    defstruct [:resource, :impl, :opts]
  end

  @type impl() :: module()

  @type state() :: %State{
          resource: any(),
          impl: impl(),
          opts: opts()
        }

  @type opt() ::
          {:name, GenServer.name()}
          | {:key, atom()}
          | {:sleep_after, non_neg_integer()}
          | {:type, impl()}
          | {atom(), any()}

  @type opts() :: [opt()]

  @impl GenServer
  def init(opts) do
    if not Keyword.has_key?(opts, :type) do
      raise ":type option is required."
    end

    impl = opts[:type]
    {:ok, %State{resource: impl.init(opts), impl: impl, opts: opts}}
  end

  @impl GenServer
  def handle_call({:read, message}, from, %State{} = state) do
    {answer, info} = state.impl.read(message, state.resource)

    GenServer.reply(from, answer)
    state.impl.after_reply(info, state.resource)

    execute_telemetry(:read, message, answer, state)
    sleep(state.opts)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:write, message}, %State{} = state) do
    :ok = state.impl.write(message, state.resource)

    execute_telemetry(:write, message, nil, state)
    sleep(state.opts)
    {:noreply, state}
  end

  @spec start_link(opts()) :: GenServer.on_start()
  def start_link(opts) do
    name = opts[:name]
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  defp execute_telemetry(event, query, answer, state) do
    :telemetry.execute(
      [:lab_live, :instrument, event],
      %{query: query, answer: answer, state: state}
    )
  end

  defp sleep(opts) do
    with sleep_time <- Keyword.get(opts, :sleep_after, 0),
         true <- sleep_time > 0 do
      Process.sleep(sleep_time)
    end
  end

  def read(pid, message) when is_binary(message) do
    GenServer.call(pid, {:read, message})
  end

  def read(pid, model, key, opts \\ []) when is_atom(key) and is_list(opts) do
    {query, parser} = Model.get_reader(model, key, opts)
    read(pid, query) |> parser.()
  end

  def read_joined(pid, model, keys_and_opts) when is_list(keys_and_opts) do
    {query, parser} = Model.get_joined_reader(model, keys_and_opts)
    read(pid, query) |> parser.()
  end

  def write(pid, message) when is_binary(message) do
    GenServer.cast(pid, {:write, message})
  end

  def write(pid, model, key, opts \\ []) do
    query = Model.get_writer(model, key, opts)
    write(pid, query)
  end

  def write_joined(pid, model, keys_and_opts) when is_list(keys_and_opts) do
    query = Model.get_joined_writer(model, keys_and_opts)
    write(pid, query)
  end
end
