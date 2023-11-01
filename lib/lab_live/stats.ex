defmodule LabLive.Stats do
  defstruct size: 0, max_size: :inf, sum: 0, square_sum: 0, queue: :queue.new()

  @type max_size :: non_neg_integer() | :inf
  @type size :: non_neg_integer()

  @type t :: %LabLive.Stats{
          size: size(),
          max_size: max_size(),
          sum: number(),
          square_sum: number(),
          queue: :queue.queue()
        }

  @doc """
  Create a new stats struct.
      iex> LabLive.Stats.new([1, 2, 3])
      %LabLive.Stats{max_size: :inf, queue: {[3, 2], [1]}, size: 3, square_sum: 14, sum: 6}

      iex> LabLive.Stats.new([1, 2, 3], 2)
      ** (RuntimeError) list size(3) must be same or less than max_size(2).
  """
  @spec new(list(), any()) :: LabLive.Stats.t()
  def new(list \\ [], max_size \\ :inf) when is_list(list) do
    if max_size != :inf do
      if length(list) > max_size do
        raise "list size(#{length(list)}) must be same or less than max_size(#{max_size})."
      end
    end

    %LabLive.Stats{
      size: length(list),
      max_size: max_size,
      sum: Enum.sum(list),
      square_sum: Enum.sum(for x <- list, do: x * x),
      queue: :queue.from_list(list)
    }
  end

  def refresh(stats = %LabLive.Stats{}) do
    new(stats.max_size)
  end

  @spec append_anyway(LabLive.Stats.t(), number()) :: LabLive.Stats.t()
  def append_anyway(stats = %LabLive.Stats{}, value) do
    %LabLive.Stats{
      size: stats.size + 1,
      max_size: stats.max_size,
      sum: stats.sum + value,
      square_sum: stats.square_sum + value * value,
      queue: :queue.in(value, stats.queue)
    }
  end

  @doc """
  Drop the oldest value from the queue.
      iex> LabLive.Stats.new([1, 2, 3]) |> LabLive.Stats.drop_oldest()
      %LabLive.Stats{size: 2, max_size: :inf, sum: 5, square_sum: 13, queue: {[3], [2]}}
  """
  @spec drop_oldest(LabLive.Stats.t()) :: LabLive.Stats.t()
  def drop_oldest(stats = %LabLive.Stats{}) do
    {{:value, dropped}, new_queue} = :queue.out(stats.queue)

    %LabLive.Stats{
      size: stats.size - 1,
      max_size: stats.max_size,
      sum: stats.sum - dropped,
      square_sum: stats.square_sum - dropped * dropped,
      queue: new_queue
    }
  end

  @doc """
  Append a value to the queue.
  The oldest value will be dropped if the queue is full.

      iex> LabLive.Stats.new([1, 2, 3], 5) |> LabLive.Stats.append(4)
      %LabLive.Stats{size: 4, max_size: 5, sum: 10, square_sum: 30, queue: {[4, 3, 2], [1]}}

      iex> LabLive.Stats.new([1, 2, 3], 3) |> LabLive.Stats.append(4)
      %LabLive.Stats{size: 3, max_size: 3, sum: 9, square_sum: 29, queue: {[4], [2, 3]}}
  """
  @spec append(LabLive.Stats.t(), number()) :: LabLive.Stats.t()
  def append(stats = %LabLive.Stats{}, value) do
    new_stats = append_anyway(stats, value)

    if stats.max_size == :inf do
      new_stats
    else
      if new_stats.size > stats.max_size do
        new_stats |> drop_oldest()
      else
        new_stats
      end
    end
  end

  @doc """
  Calculate the variance of the queue.
      iex> LabLive.Stats.new([1, 2, 3, 4, 5, 6, 7]) |> LabLive.Stats.variance()
      4.0

      iex> LabLive.Stats.new() |> LabLive.Stats.variance()
      nil
  """
  @spec variance(LabLive.Stats.t()) :: nil | float()
  def variance(stats) do
    if stats.size > 0 do
      (stats.square_sum - stats.sum * stats.sum / stats.size) / stats.size
    else
      nil
    end
  end

  @doc """
  Calculate the variance of the queue.
      iex> LabLive.Stats.new([1, 2, 3, 4, 5, 6, 7]) |> LabLive.Stats.stddev()
      2.0

      iex> LabLive.Stats.new() |> LabLive.Stats.stddev()
      nil
  """
  @spec stddev(LabLive.Stats.t()) :: nil | float()
  def stddev(stats) do
    case variance(stats) do
      nil -> nil
      var -> :math.sqrt(var)
    end
  end

  @doc """
  Calculate the mean of the queue.
      iex> LabLive.Stats.new([1, 2, 3, 4, 5, 6, 7]) |> LabLive.Stats.mean()
      4.0
  """
  @spec mean(LabLive.Stats.t()) :: nil | float()
  def mean(stats) do
    if stats.size > 0 do
      stats.sum / stats.size
    else
      0
    end
  end
end
