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
      method_opts: specs[method] || [model: specs[:model]]
    ]

    model = %{model: specs[:model]}
    ConnectionManager.start_instrument(manager, key, model, opts)
  end

  def start_instruments(specs_map) do
    start_instruments(ConnectionManager, specs_map)
  end

  def start_instruments(manager, specs_map)
      when is_atom(manager) and (is_map(specs_map) or is_list(specs_map)) do
    for {inst_key, specs} <- specs_map do
      {inst_key, start_instrument(manager, inst_key, specs[:selected_type], specs)}
    end
  end

  def start_instruments(manager \\ ConnectionManager, specs_map, connections) do
    for {inst_key, method} <- connections do
      {inst_key, start_instrument(manager, inst_key, :"#{method}", specs_map[inst_key])}
    end
  end

  def query(inst_key, query_key) do
    query(inst_key, query_key, [])
  end

  def query(inst_key, query_key, query_params)
      when is_atom(query_key) and is_list(query_params) do
    query(ConnectionManager, inst_key, query_key, query_params)
  end

  def query(manager, inst_key, query_key) when is_atom(query_key) do
    query(manager, inst_key, query_key, [])
  end

  def query(manager, inst_key, query_key, query_params)
      when is_atom(inst_key) and is_atom(query_key) and is_list(query_params) do
    {pid, %{model: model}} = ConnectionManager.lookup(manager, inst_key)

    case Model.get_format_pair(model, query_key, query_params) do
      {input, nil} ->
        Connection.write(pid, input)

      {input, parser} ->
        Connection.read(pid, input) |> parser.()
    end
  end

  def read(inst_key, query_key) when is_atom(query_key) do
    read(inst_key, query_key, [])
  end

  def read(inst_key, query_key, query_params) when is_atom(query_key) and is_list(query_params) do
    query(ConnectionManager, inst_key, query_key, query_params)
  end

  def read(manager, inst_key, query_key) when is_atom(query_key) do
    read(manager, inst_key, query_key, [])
  end

  def read(manager, inst_key, query_key, query_params)
      when is_atom(query_key) and is_list(query_params) do
    {pid, %{model: model}} = ConnectionManager.lookup(manager, inst_key)
    {input, parser} = Model.get_format_pair(model, query_key, query_params)
    Connection.read(pid, input) |> parser.()
  end

  def read_joined(manager \\ ConnectionManager, inst_key, keys_and_params) do
    {pid, %{model: model}} = ConnectionManager.lookup(manager, inst_key)
    {input, parser} = Model.get_joined_format_pair(model, keys_and_params)
    Connection.read(pid, input) |> parser.()
  end

  def write(inst_key, query_key) when is_atom(query_key) do
    write(inst_key, query_key, [])
  end

  def write(inst_key, query_key, query_params)
      when is_atom(query_key) and is_list(query_params) do
    query(ConnectionManager, inst_key, query_key, query_params)
  end

  def write(manager, inst_key, query_key) when is_atom(query_key) do
    write(manager, inst_key, query_key, [])
  end

  def write(manager, inst_key, query_key, query_params)
      when is_atom(query_key) and is_list(query_params) do
    {pid, %{model: model}} = ConnectionManager.lookup(manager, inst_key)
    {input, _} = Model.get_format_pair(model, query_key, query_params)
    :ok = Connection.write(pid, input)
  end

  def write_joined(manager \\ ConnectionManager, inst_key, keys_and_params) do
    {pid, %{model: model}} = ConnectionManager.lookup(manager, inst_key)
    {input, _} = Model.get_joined_format_pair(model, keys_and_params)
    :ok = Connection.write(pid, input)
  end

  def read_text(manager \\ ConnectionManager, inst_key, message) when is_binary(message) do
    ConnectionManager.pid(manager, inst_key) |> Connection.read(message)
  end

  def write_text(manager \\ ConnectionManager, inst_key, message) when is_binary(message) do
    ConnectionManager.pid(manager, inst_key) |> Connection.write(message)
  end
end
