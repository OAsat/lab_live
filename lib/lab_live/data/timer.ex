defmodule LabLive.Data.Timer do
  defstruct [:threshold, :start_time]

  alias LabLive.Data

  @type t() :: %__MODULE__{
          threshold: non_neg_integer(),
          start_time: Time.t()
        }

  def init(threshold) do
    %__MODULE__{threshold: threshold, start_time: Timex.now()}
  end

  @doc """
  Check if the timer has elapsed.
      iex> timer = LabLive.Data.Timer.init(0)
      iex> Process.sleep(1)
      iex> LabLive.Data.Timer.timer_elapsed?(timer)
      true
  """
  def timer_elapsed?(%__MODULE__{threshold: threshold, start_time: start_time}) do
    Timex.diff(Timex.now(), start_time, :millisecond) > threshold
  end

  def reset(key) when is_atom(key) do
    Data.get(key) |> reset() |> Data.update(key)
  end

  @doc """
  Reset the timer.
      iex> first = LabLive.Data.Timer.init(0)
      iex> updated = LabLive.Data.Timer.reset(first)
      iex> Timex.diff(updated.start_time, first.start_time) > 0
      true
      iex> first.threshold == updated.threshold
      true
  """
  def reset(%__MODULE__{} = timer) do
    %{timer | start_time: Timex.now()}
  end
end
