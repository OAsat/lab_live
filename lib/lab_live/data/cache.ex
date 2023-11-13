defmodule LabLive.Data.Cache do
  @moduledoc """
  Fixed length cache.


      iex> alias LabLive.Data.Cache
      iex> cache = Cache.new(3)
      iex> Cache.to_list(cache)
      []
      iex> cache = Cache.update(cache, 2)
      iex> Cache.to_list(cache)
      [2]
      iex> cache = Cache.update(cache, 3)
      iex> Cache.to_list(cache)
      [2, 3]
      iex> cache = Cache.update(cache, 4)
      iex> Cache.to_list(cache)
      [2, 3, 4]
      iex> cache = Cache.update(cache, 5)
      iex> Cache.to_list(cache)
      [3, 4, 5]
      iex> cache = Cache.update(cache, 6)
      iex> Cache.to_list(cache)
      [4, 5, 6]
  """
  defstruct size: 0, max_size: :inf, queue: :queue.new()

  alias LabLive.Data
  @behaviour Data.Behaviour

  @type size :: non_neg_integer()
  @type max_size :: size() | :inf

  @type t :: %__MODULE__{
          size: size(),
          max_size: max_size(),
          queue: :queue.queue()
        }

  @impl Data.Behaviour
  @spec new(max_size()) :: t()
  def new(max_size) do
    %__MODULE__{max_size: max_size}
  end

  @doc """
  Append a value to the queue.
  The oldest value will be dropped if the queue is full.
  """
  @impl Data.Behaviour
  @spec update(t(), any()) :: t()
  def update(cache = %__MODULE__{}, value) do
    new_cache = append_anyway(cache, value)

    if cache.max_size == :inf do
      new_cache
    else
      if new_cache.size > cache.max_size do
        new_cache |> drop_oldest()
      else
        new_cache
      end
    end
  end

  @doc """
  Get the latest value from the queue.

      iex> cache = LabLive.Data.Cache.new(:inf)
      iex> LabLive.Data.Cache.value(cache)
      :empty
      iex> cache = LabLive.Data.Cache.update(cache, 20)
      iex> LabLive.Data.Cache.value(cache)
      20
      iex> LabLive.Data.Cache.value(cache)
      20
      iex> cache = LabLive.Data.Cache.update(cache, 1)
      iex> LabLive.Data.Cache.value(cache)
      1
  """
  @impl Data.Behaviour
  @spec value(t()) :: any()
  def value(%__MODULE__{queue: queue}) do
    case :queue.peek_r(queue) do
      {:value, value} -> value
      :empty -> :empty
    end
  end

  @doc """
  Returns a string representing the latest value.

      iex> cache = LabLive.Data.Cache.new(:inf)
      iex> LabLive.Data.Cache.to_string(cache)
      "empty"
      iex> cache = LabLive.Data.Cache.update(cache, 2)
      iex> LabLive.Data.Cache.to_string(cache)
      "2"
  """
  @impl Data.Behaviour
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = data) do
    "#{value(data)}"
  end

  @spec reset(t()) :: t()
  def reset(%__MODULE__{max_size: max_size}) do
    new(max_size)
  end

  defp append_anyway(cache = %__MODULE__{}, value) do
    %__MODULE__{
      size: cache.size + 1,
      max_size: cache.max_size,
      queue: :queue.in(value, cache.queue)
    }
  end

  defp drop_oldest(cache = %__MODULE__{}) do
    {{:value, _}, new_queue} = :queue.out(cache.queue)

    %__MODULE__{
      size: cache.size - 1,
      max_size: cache.max_size,
      queue: new_queue
    }
  end

  @spec from_list(list(), max_size()) :: t()
  def from_list(list \\ [], max_size \\ :inf) when is_list(list) do
    if max_size != :inf do
      if length(list) > max_size do
        raise "list size(#{length(list)}) must be same or less than max_size(#{max_size})."
      end
    end

    %__MODULE__{
      size: length(list),
      max_size: max_size,
      queue: :queue.from_list(list)
    }
  end

  @doc """
  Returns the values in the cache as a list.

      iex> cache = LabLive.Data.Cache.new(2)
      iex> LabLive.Data.Cache.to_list(cache)
      []
      iex> cache = LabLive.Data.Cache.update(cache, 1)
      iex> LabLive.Data.Cache.to_list(cache)
      [1]
      iex> cache = LabLive.Data.Cache.update(cache, 2)
      iex> LabLive.Data.Cache.to_list(cache)
      [1, 2]
  """
  @spec to_list(t()) :: list()
  def to_list(%__MODULE__{queue: queue}) do
    :queue.to_list(queue)
  end
end
