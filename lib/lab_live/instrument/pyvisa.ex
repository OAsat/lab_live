defmodule LabLive.Instrument.Pyvisa do
  alias LabLive.Instrument

  @behaviour Instrument
  @python_src File.cwd!() |> Path.join("python/lab_live_pyvisa") |> to_charlist()

  @impl Instrument
  def init(opts) do
    python = Keyword.get(opts, :python)
    address = Keyword.get(opts, :address)
    python_pid = start_python(python)
    {python_pid, address}
  end

  @impl Instrument
  def read(message, {python_pid, address}) do
    answer =
      :python.call(python_pid, :communicate, :query, [address, message])
      |> to_string()

    {answer, nil}
  end

  @impl Instrument
  def after_reply(nil, _state) do
    nil
  end

  @impl Instrument
  def write(message, {python_pid, address}) do
    :python.call(python_pid, :communicate, :write, [address, message])
    :ok
  end

  defp start_python(python_exec) do
    {:ok, pid} =
      :python.start_link(python_path: @python_src, python: to_charlist(python_exec))

    pid
  end
end
