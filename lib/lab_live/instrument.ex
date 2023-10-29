defmodule LabLive.Instrument do
  @moduledoc """
  Sever to communicate with measurement instruments.

  See `LabLive.Instrument.Dummy`, `LabLive.Instrument.Tcp`, and `LabLive.Instrument.Pyvisa` for examples.

  ### Example
  (For the definition of `Lakeshore350.dummy/0` and `Lakeshore350`, see `LabLive.Model`.)
      iex> map = Lakeshore350.dummy()
      iex> {:ok, pid} = LabLive.Instrument.start_link({:ls350, LabLive.Instrument.Dummy, map: map})
      iex> LabLive.Instrument.read(pid, "SETP? 2\\n")
      "1.0\\r\\n"
      iex> LabLive.Instrument.read(pid, Lakeshore350, :ramp, channel: 2)
      %{onoff: 1, kpermin: 0.2}
      iex> LabLive.Instrument.read_joined(pid, Lakeshore350, sensor: [channel: "A"], heater: [channel: 2])
      %{sensor: %{ohm: 1200.0}, heater: %{percentage: 56.7}}
  """
  @callback init(opts :: any()) :: state :: any()
  @callback read(message :: binary(), state :: any()) :: {answer :: binary(), info :: any()}
  @callback after_reply(info :: any(), state :: any()) :: any()
  @callback write(message :: binary(), state :: any()) :: :ok

  use GenServer

  @impl GenServer
  def init({name, impl, opts}) do
    state = impl.init(opts)
    {:ok, {name, impl, state, opts}}
  end

  @impl GenServer
  def handle_call({:read, message}, from, stored = {name, impl, state, opts}) do
    {answer, info} = impl.read(message, state)

    GenServer.reply(from, answer)
    impl.after_reply(info, state)

    :telemetry.execute(
      [:lab_live, :instrument, :read],
      %{message: message, answer: answer},
      %{process: self(), state: stored, name: name}
    )

    sleep_after = Keyword.get(opts, :sleep_after, 0)

    if sleep_after > 0 do
      Process.sleep(sleep_after)
    end

    {:noreply, stored}
  end

  @impl GenServer
  def handle_cast({:write, message}, stored = {name, impl, state, opts}) do
    :ok = impl.write(message, state)

    sleep_after = Keyword.get(opts, :sleep_after, 0)

    :telemetry.execute(
      [:lab_live, :instrument, :write],
      %{message: message, answer: nil},
      %{process: self(), state: stored, name: name}
    )

    if sleep_after > 0 do
      Process.sleep(sleep_after)
    end

    {:noreply, stored}
  end

  @spec start_link({atom(), module(), Keyword.t()}) :: GenServer.on_start()
  def start_link({name, impl, opts}) do
    GenServer.start_link(__MODULE__, {name, impl, opts}, name: name)
  end

  def read(pid, message) when is_binary(message) do
    GenServer.call(pid, {:read, message})
  end

  def read(pid, model, key, opts \\ []) when is_atom(key) and is_list(opts) do
    {query, parser} = LabLive.Model.get_reader(model, key, opts)
    read(pid, query) |> parser.()
  end

  def read_joined(pid, model, keys_and_opts) when is_list(keys_and_opts) do
    {query, parser} = LabLive.Model.get_joined_reader(model, keys_and_opts)
    read(pid, query) |> parser.()
  end

  def write(pid, message) when is_binary(message) do
    GenServer.cast(pid, {:write, message})
  end

  def write(pid, model, key, opts \\ []) do
    query = LabLive.Model.get_writer(model, key, opts)
    write(pid, query)
  end

  def write_joined(pid, model, keys_and_opts) when is_list(keys_and_opts) do
    query = LabLive.Model.get_joined_writer(model, keys_and_opts)
    write(pid, query)
  end
end
