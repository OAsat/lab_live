defmodule LabLive.DataWriter do
  use GenServer

  @impl GenServer
  def init({filename, labels, opts}) do
    file_opts = Keyword.get(opts, :file_opts, [:exclusive, {:delayed_write, 1000, 1000}])
    {:ok, file} = File.open(filename, file_opts)
    IO.binwrite(file, "#{header(labels)}\n")
    {:ok, {file, labels}}
  end

  @impl GenServer
  def handle_call({:write_line, data}, _from, state = {file, labels}) do
    new_line = data_to_string(data, labels)
    case IO.binwrite(file, "#{new_line}\n") do
      :ok -> {:reply, new_line, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl GenServer
  def terminate(_reason, {file, _}) do
    File.close(file)
  end

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: __MODULE__)
  end

  def write_line(pid, data) do
    GenServer.call(pid, {:write_line, data})
  end

  def data_to_string(data, labels) do
    labels
    |> Enum.map(fn {key, _} ->
      Keyword.get(data, key) |> to_string()
    end)
    |> Enum.join(",")
  end

  def header(labels) do
    Keyword.values(labels)
    |> Enum.join(",")
  end
end
