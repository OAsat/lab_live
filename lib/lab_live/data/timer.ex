defmodule LabLive.Data.Timer do
  @moduledoc """
  Timer struct.
  """
  defstruct [:threshold, :start_time]
  alias LabLive.Data
  @behaviour Data.Behaviour

  @type t() :: %__MODULE__{
          threshold: non_neg_integer(),
          start_time: Time.t()
        }

  @impl Data.Behaviour
  def new(threshold) do
    %__MODULE__{threshold: threshold, start_time: Timex.now()}
  end

  @doc """
  Check if the timer has elapsed.
      iex> timer = LabLive.Data.Timer.new(0)
      iex> LabLive.Data.Timer.value(timer)
      true
  """
  @impl Data.Behaviour
  def value(%__MODULE__{threshold: threshold} = timer) do
    diff_now(timer) >= threshold
  end

  @doc """
  Reset the timer.
      iex> first = LabLive.Data.Timer.new(0)
      iex> Process.sleep(1)
      iex> updated = LabLive.Data.Timer.update(first, nil)
      iex> Timex.diff(updated.start_time, first.start_time) > 0
      true
      iex> first.threshold == updated.threshold
      true
  """
  @impl Data.Behaviour
  def update(%__MODULE__{} = timer, nil) do
    %{timer | start_time: Timex.now()}
  end

  @doc """
  to_string
      iex> LabLive.Data.Timer.new(1000) |> LabLive.Data.Timer.to_string()
      "timer < 1000ms"
  """
  @impl Data.Behaviour
  def to_string(%__MODULE__{} = timer) do
    if value(timer) do
      "timer >= #{timer.threshold}ms"
    else
      "timer < #{timer.threshold}ms"
    end
  end

  def diff_now(%__MODULE__{start_time: start}) do
    Timex.diff(Timex.now(), start, :millisecond)
  end
end
