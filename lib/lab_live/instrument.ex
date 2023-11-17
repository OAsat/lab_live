defmodule LabLive.Instrument do
  alias LabLive.ConnectionManager
  alias LabLive.Connection
  alias LabLive.Model

  def load_toml_file(file) do
    File.read!(file)
    |> Toml.decode!(keys: :atoms)
    |> transform_loaded_map(file)
  end

  defp transform_loaded_map(map, path) do
    for {inst_key, content} <- map do
      model_path = Path.dirname(path) |> Path.join(content[:model])
      {inst_key, %{content | model: Model.from_file(model_path)}}
    end
    |> Enum.into(%{})
  end

  defp map_method(type_atom) do
    case type_atom do
      :dummy -> Connection.Method.Dummy
      :pyvisa -> Connection.Method.Pyvisa
      :tcp -> Connection.Method.Tcp
      fallback -> fallback
    end
  end

  defp start_instrument(manager, key, method, specs) do
    opts = [
      sleep_after_reply: specs[:sleep_after_reply],
      method: map_method(method),
      method_opts: specs[method] |> Map.to_list()
    ]

    model = %{model: specs[:model]}
    ConnectionManager.start_instrument(manager, key, model, opts)
  end

  def start_instruments(manager \\ ConnectionManager, specs_map, connections \\ []) do
    for {inst_key, method} <- connections do
      {inst_key, start_instrument(manager, inst_key, :"#{method}", specs_map[inst_key])}
    end
  end

  def query(manager \\ ConnectionManager, inst_key, query_key, query_params) do
    {pid, %{model: model}} = ConnectionManager.lookup(manager, inst_key)

    case Model.get_format_pair(model, query_key, query_params) do
      {input, nil} ->
        Connection.write(pid, input)

      {input, parser} ->
        Connection.read(pid, input) |> parser.()
    end
  end

  def read(manager \\ ConnectionManager, inst_key, message) do
    ConnectionManager.pid(manager, inst_key) |> Connection.read(message)
  end

  def write(manager \\ ConnectionManager, inst_key, message) do
    ConnectionManager.pid(manager, inst_key) |> Connection.write(message)
  end
end
