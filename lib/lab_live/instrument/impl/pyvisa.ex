defmodule LabLive.Instrument.Impl.Pyvisa do
  alias LabLive.Instrument.Impl
  @behaviour Impl

  @python_src File.cwd!() |> Path.join("python/lab_live_pyvisa") |> to_charlist()

  @impl Impl
  def init(opts) do
    if not Keyword.has_key?(opts, :address) do
      raise ":address option is required for #{__MODULE__}."
    end

    python = Keyword.get(opts, :python)
    address = Keyword.get(opts, :address)
    {:ok, python_pid} = start_python(python)
    {python_pid, address}
  end

  @impl Impl
  def read(message, {python_pid, address}) do
    answer =
      :python.call(python_pid, :communicate, :query, [address, message])
      |> to_string()

    {answer, nil}
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

  defp start_python(python_exec) do
    case python_exec do
      nil ->
        :python.start_link(python_path: @python_src)

      python_exec ->
        :python.start_link(python_path: @python_src, python: to_charlist(python_exec))
    end
  end
end
