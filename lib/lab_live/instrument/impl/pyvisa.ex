defmodule LabLive.Instrument.Impl.Pyvisa do
  alias LabLive.Instrument.Impl
  @behaviour Impl

  @python_src File.cwd!() |> Path.join("python/lab_live_pyvisa") |> to_charlist()

  @impl Impl
  def init(opts) do
    {:ok, python_pid} = start_python(opts[:python])
    {python_pid, opts[:address] || raise(":address option is required")}
  end

  @impl Impl
  def read(message, {python_pid, address}) do
    {
      :python.call(python_pid, :communicate, :query, [address, message]) |> to_string(),
      nil
    }
  end

  @impl Impl
  def after_reply(nil, _state) do
    :ok
  end

  @impl Impl
  def write(message, {python_pid, address}) do
    :python.call(python_pid, :communicate, :write, [address, message])
    :ok
  end

  @impl Impl
  def terminate(_reason, {python_pid, _address}) do
    :python.stop(python_pid)
  end

  defp start_python(nil) do
    :python.start_link(python_path: @python_src)
  end

  defp start_python(python_exec) do
    :python.start_link(python_path: @python_src, python: to_charlist(python_exec))
  end
end
