defmodule LabLive.Data do
  alias LabLive.StorageManager
  alias LabLive.Storage
  alias LabLive.DataInfo

  @type manager() :: StorageManager.manager()
  @type key() :: StorageManager.key()
  @type content() :: Storage.content()
  @type data() :: Storage.content()
  @type info() :: DataInfo.t()
  @type data_specs() :: [init: data(), info: info()]
  @type many_data() :: [{key(), data_specs()}] | %{key() => data_specs()}

  alias LabLive.StorageManager

  @manager StorageManager

  @spec start_data(manager :: StorageManager.manager(), many_data :: many_data()) ::
          [{key(), StorageManager.on_start_data()}]
  def start_data(manager \\ __MODULE__, many_data) do
    for {name, data_specs} <- many_data do
      {name, StorageManager.start_data(manager, name, data_specs[:init], data_specs[:info])}
    end
  end

  @spec get(manager(), key()) :: content()
  def get(manager \\ @manager, key), do: get_pid(manager, key) |> Storage.get()

  @spec value(manager(), key()) :: any()
  def value(manager \\ @manager, key), do: get_pid(manager, key) |> Storage.value()

  @spec next(manager(), key()) :: :ok
  def next(manager \\ @manager, key), do: get_pid(manager, key) |> Storage.update()

  @spec update(manager(), any(), key()) :: :ok
  def update(manager \\ @manager, new, key), do: Storage.update(new, get_pid(manager, key))

  @spec override(manager(), content(), key()) :: :ok
  def override(manager \\ @manager, data, key), do: Storage.override(data, get_pid(manager, key))

  @spec info(manager(), key()) :: info()
  def info(manager \\ @manager, key) do
    StorageManager.info(manager, key)
  end

  @spec label(manager(), key()) :: String.t()
  def label(manager \\ @manager, key) do
    info(manager, key)[:label]
  end

  def get_many(list) when is_list(list) do
    for key <- list do
      {key, get(key)}
    end
  end

  @spec update_many([{key(), any()}]) :: [{key(), :ok}]
  def update_many(list) when is_list(list) do
    for {key, value} <- list do
      {key, update(value, key)}
    end
  end

  def get_many_value(list) when is_list(list) do
    for key <- list do
      {key, value(key)}
    end
  end

  defp get_pid(manager, key), do: StorageManager.pid(manager, key)
end
