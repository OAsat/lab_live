defmodule LabLive.Data.Timer do
  @moduledoc """
  Timer which returns true if the provided amount of time has been elapsed.
  """
  defstruct [:threshold, :start_time]
  alias LabLive.Data
  @behaviour Data.Behaviour

  @type t() :: %__MODULE__{
          threshold: non_neg_integer() | :inf,
          start_time: Time.t()
        }

  @impl Data.Behaviour
  def new(threshold) do
    %__MODULE__{threshold: threshold, start_time: Time.utc_now()}
  end

  @doc """
  True if the timer has elapsed.

      iex> timer = LabLive.Data.Timer.new(0)
      iex> LabLive.Data.Timer.value(timer)
      true

      iex> timer = LabLive.Data.Timer.new(100_000_000)
      iex> LabLive.Data.Timer.value(timer)
      false

      iex> timer = LabLive.Data.Timer.new(:inf)
      iex> LabLive.Data.Timer.value(timer)
      false
  """
  @impl Data.Behaviour
  def value(%__MODULE__{threshold: threshold} = timer) do
    diff_now(timer) >= threshold
  end

  @doc """
  Resets the start-time of the timer.
      iex> first = LabLive.Data.Timer.new(0)
      iex> Process.sleep(1)
      iex> updated = LabLive.Data.Timer.update(first, nil)
      iex> Time.diff(updated.start_time, first.start_time, :millisecond) > 0
      true
      iex> first.threshold == updated.threshold
      true
  """
  @impl Data.Behaviour
  def update(%__MODULE__{} = timer, nil) do
    %{timer | start_time: Time.utc_now()}
  end

  @doc """
  to_string

  ```
  timer = LabLive.Data.Timer.new(2_000)
  LabLive.Data.Timer.to_string(timer)
  #=> "false (0 ms < 2000 ms)"
  Process.sleep(1_000)
  LabLive.Data.Timer.to_string(timer)
  #=> "false (1000 ms < 2000 ms)"
  Process.sleep(1_000)
  LabLive.Data.Timer.to_string(timer)
  #=> "true (2002 ms >= 2000 ms)"
  ```
  """
  @impl Data.Behaviour
  def to_string(%__MODULE__{} = timer) do
    if value(timer) do
      "true (#{diff_now(timer)} ms >= #{timer.threshold} ms)"
    else
      "false (#{diff_now(timer)} ms < #{timer.threshold} ms)"
    end
  end

  def diff_now(%__MODULE__{start_time: start}) do
    Time.diff(Time.utc_now(), start, :millisecond)
  end
end
