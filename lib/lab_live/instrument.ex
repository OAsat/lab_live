defmodule LabLive.Instrument do
  @moduledoc """
  Sever to communicate with measurement instruments.

  See `LabLive.Instrument.Dummy`, `LabLive.Instrument.Tcp`, and `LabLive.Instrument.Pyvisa` for examples.
  """
  @callback init(opts :: any()) :: state :: any()
  @callback read(message :: binary(), state :: any()) :: {answer :: binary(), info :: any()}
  @callback after_reply(info :: any(), state :: any()) :: any()
  @callback write(message :: binary(), state :: any()) :: :ok

  use GenServer

  @impl GenServer
  def init({impl, opts}) do
    state = impl.init(opts)
    {:ok, {impl, state, opts}}
  end

  @impl GenServer
  def handle_call({:read, message}, from, stored = {impl, state, opts}) do
    {answer, info} = impl.read(message, state)

    GenServer.reply(from, answer)

    impl.after_reply(info, state)

    sleep_after = Keyword.get(opts, :sleep_after, 0)

    if sleep_after > 0 do
      Process.sleep(sleep_after)
    end

    {:noreply, stored}
  end

  @impl GenServer
  def handle_cast({:write, message}, stored = {impl, state, opts}) do
    :ok = impl.write(message, state)

    sleep_after = Keyword.get(opts, :sleep_after, 0)

    if sleep_after > 0 do
      Process.sleep(sleep_after)
    end

    {:noreply, stored}
  end

  @spec start_link({atom(), module(), Keyword.t()}) :: GenServer.on_start()
  def start_link({name, impl, opts}) do
    GenServer.start_link(__MODULE__, {impl, opts}, name: name)
  end

  def read(pid, message) do
    GenServer.call(pid, {:read, message})
  end

  def write(pid, message) do
    GenServer.cast(pid, {:write, message})
  end
end
