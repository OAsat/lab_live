defmodule LabLive.Connection.Method.Pyvisa do
  alias LabLive.Connection.Method
  @behaviour Method

  @type opt() :: {:python, String.t()} | {:address, String.t()}
  @type opts() :: [opt()]

  @python_src File.cwd!() |> Path.join("python/lab_live_pyvisa") |> to_charlist()

  @impl Method
  def init(opts) do
    {:ok, python_pid} = start_python(opts[:python])
    {python_pid, opts[:address] || raise(":address option is required")}
  end

  @impl Method
  def read(message, {python_pid, address}) do
    :python.call(python_pid, :communicate, :query, [address, message]) |> to_string()
  end

  @impl Method
  def write(message, {python_pid, address}) do
    :python.call(python_pid, :communicate, :write, [address, message])
    :ok
  end

  @impl Method
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
