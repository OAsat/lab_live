defmodule LabLive.Instrument.Pyvisa do
  alias LabLive.Instrument

  use GenServer
  @behaviour Instrument
  @python_src File.cwd!() |> Path.join("python/lab_live_pyvisa") |> to_charlist()
  defp get_opts(opts) do
    python = Keyword.get(opts, :python)
    address = Keyword.get(opts, :address)
    sleep_after = Keyword.get(opts, :sleep_after, 0)
    {python, address, sleep_after}
  end

  @impl GenServer
  def init(opts) do
    {python, _address, _sleep_after} = get_opts(opts)
    python_pid = start_python(python)
    {:ok, {python_pid, opts}}
  end

  @impl GenServer
  def handle_call({:read, message}, from, state = {python_pid, opts}) do
    {_python, address, sleep_after} = get_opts(opts)

    answer =
      :python.call(python_pid, :communicate, :query, [address, message])
      |> to_string()

    if sleep_after > 0 do
      Process.sleep(sleep_after)
    end

    GenServer.reply(from, answer)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:write, message}, state = {python_pid, opts}) do
    {_python, address, sleep_after} = get_opts(opts)
    :python.call(python_pid, :communicate, :write, [address, message])

    if sleep_after > 0 do
      Process.sleep(sleep_after)
    end

    {:noreply, state}
  end

  @impl Instrument
  def start_link({name, opts}) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl Instrument
  def read(pid, message, _opts \\ nil) do
    GenServer.call(pid, {:read, message})
  end

  @impl Instrument
  def write(pid, message, _opts \\ nil) do
    GenServer.cast(pid, {:write, message})
  end

  defp start_python(python_exec) do
    {:ok, pid} =
      :python.start_link(python_path: @python_src, python: to_charlist(python_exec))

    pid
  end
end
