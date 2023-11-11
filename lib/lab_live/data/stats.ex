defmodule LabLive.Data.Stats do
  defstruct size: 0, max_size: :inf, sum: 0, square_sum: 0, queue: :queue.new()

  alias LabLive.Data
  @behaviour Data.Behaviour

  @type max_size :: non_neg_integer() | :inf
  @type size :: non_neg_integer()

  @type t :: %LabLive.Data.Stats{
          size: size(),
          max_size: max_size(),
          sum: number(),
          square_sum: number(),
          queue: :queue.queue()
        }

  @impl Data.Behaviour
  def new(max_size) do
    %__MODULE__{max_size: max_size}
  end

  @doc """
  Append a value to the queue.
  The oldest value will be dropped if the queue is full.
  """
  @impl Data.Behaviour
  @spec update(LabLive.Data.Stats.t(), number()) :: LabLive.Data.Stats.t()
  def update(stats = %__MODULE__{}, value) do
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
  Get the latest value from the queue.

      iex> stats = LabLive.Data.Stats.new(:inf)
      iex> LabLive.Data.Stats.value(stats)
      :empty
      iex> stats = LabLive.Data.Stats.update(stats, 20)
      iex> LabLive.Data.Stats.value(stats)
      20
      iex> stats = LabLive.Data.Stats.update(stats, 1)
      iex> LabLive.Data.Stats.value(stats)
      1
  """
  @impl Data.Behaviour
  def value(%__MODULE__{queue: queue}) do
    case :queue.peek_r(queue) do
      {:value, value} -> value
      :empty -> :empty
    end
  end

  @doc """
  to string.

      iex> stats = LabLive.Data.Stats.new(:inf)
      iex> LabLive.Data.Stats.to_string(stats)
      "size: 0, max_size: inf, sum: 0, square_sum: 0, queue: []"
      iex> stats = LabLive.Data.Stats.update(stats, 2)
      iex> LabLive.Data.Stats.to_string(stats)
      "size: 1, max_size: inf, sum: 2, square_sum: 4, queue: [2]"
  """
  @impl Data.Behaviour
  def to_string(%__MODULE__{} = data) do
    [
      "size: #{data.size}",
      "max_size: #{data.max_size}",
      "sum: #{data.sum}",
      "square_sum: #{data.square_sum}",
      "queue: #{data.queue |> :queue.to_list() |> inspect()}"
    ]
    |> Enum.join(", ")
  end

  def reset(%__MODULE__{max_size: max_size}) do
    new(max_size)
  end

  defp append_anyway(stats = %__MODULE__{}, value) do
    %__MODULE__{
      size: stats.size + 1,
      max_size: stats.max_size,
      sum: stats.sum + value,
      square_sum: stats.square_sum + value * value,
      queue: :queue.in(value, stats.queue)
    }
  end

  defp drop_oldest(stats = %__MODULE__{}) do
    {{:value, dropped}, new_queue} = :queue.out(stats.queue)

    %__MODULE__{
      size: stats.size - 1,
      max_size: stats.max_size,
      sum: stats.sum - dropped,
      square_sum: stats.square_sum - dropped * dropped,
      queue: new_queue
    }
  end

  @doc """
  Calculate the variance of the queue.
  """
  @spec variance(t()) :: nil | float()
  def variance(stats = %__MODULE__{}) do
    if stats.size > 0 do
      (stats.square_sum - stats.sum * stats.sum / stats.size) / stats.size
    else
      nil
    end
  end

  @doc """
  Calculate the variance of the queue.
  """
  @spec stddev(t()) :: nil | float()
  def stddev(stats = %__MODULE__{}) do
    case variance(stats) do
      nil -> nil
      var -> :math.sqrt(var)
    end
  end

  @doc """
  Calculate the mean of the queue.
  """
  @spec mean(t()) :: nil | float()
  def mean(stats = %__MODULE__{}) do
    if stats.size > 0 do
      stats.sum / stats.size
    else
      0
    end
  end
end
