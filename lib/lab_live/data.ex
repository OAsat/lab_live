defmodule LabLive.Data do
  @moduledoc """
  Functions to handle data storages.

      iex> alias LabLive.Data
      iex> {:ok, _pid} = Data.start(:a)
      iex> 10 |> Data.update(:a)
      :ok
      iex> Data.get(:a)
      10

  Starting multiple properties:
      iex> alias LabLive.Data
      iex> props = [b: [], c: [label: "label of c"]]
      iex> [b: {:ok, _pid_b}, c: {:ok, _pid_c}] = Data.start(props)
      iex> Data.opts(:c)
      [label: "label of c"]
      iex> Data.labels([:b, :c])
      [b: "b", c: "label of c"]
      iex> Data.update(%{b: 20, c: 30})
      %{b: :ok, c: :ok}
      iex> Data.get([:b, :c])
      [b: 20, c: 30]
  """
  alias LabLive.Data.StorageManager
  alias LabLive.Data.Storage

  def start(storages) when is_list(storages) or is_map(storages) do
    StorageManager.start_storage(storages)
  end

  def start(storage, opts \\ []) when is_atom(storage) and is_list(opts) do
    StorageManager.start_storage(storage, opts)
  end

  def pid(key) do
    StorageManager.info(key) |> elem(0)
  end

  def opts(key) do
    StorageManager.info(key) |> elem(1)
  end

  def stats(key) do
    pid(key) |> Storage.stats()
  end

  def label(key) do
    case Keyword.get(opts(key), :label, nil) do
      nil -> to_string(key)
      label -> label
    end
  end

  def labels(keys) do
    Enum.map(keys, fn key -> {key, label(key)} end)
  end

  @spec update(any(), atom()) :: :ok
  def update(value, key) when is_atom(key) do
    pid(key) |> Storage.update(value)
  end

  @spec update(any()) :: map()
  def update(keys_and_values) do
    for {key, value} <- keys_and_values do
      {key, update(value, key)}
    end
    |> Enum.into(%{})
  end

  @spec get(atom()) :: any()
  def get(key) when is_atom(key) do
    pid(key) |> Storage.get()
  end

  @spec get([atom()]) :: map()
  def get(keys) when is_list(keys) do
    for key <- keys do
      {key, get(key)}
    end
  end
end
