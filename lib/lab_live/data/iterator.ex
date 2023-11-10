defmodule LabLive.Data.Iterator do
  @moduledoc """
  Iteration of list.
  """
  defstruct [:count, :list]
  alias LabLive.Data
  @behaviour Data.Behaviour

  @type t() :: %__MODULE__{
          count: :not_started | non_neg_integer() | :finished,
          list: list()
        }

  @impl Data.Behaviour
  def new(list) when is_list(list) do
    %__MODULE__{count: :not_started, list: list}
  end

  @impl Data.Behaviour
  def value(%__MODULE__{} = iterator) do
    case iterator.count do
      :not_started -> :not_started
      :finished -> :finished
      count -> iterator.list |> Enum.at(count)
    end
  end

  @impl Data.Behaviour
  def update(%__MODULE__{} = iterator, nil) do
    %__MODULE__{iterator | count: step_count(iterator)}
  end

  @impl Data.Behaviour
  def to_string(%__MODULE__{} = iterator) do
    list_str = iterator.list |> Enum.map(&Kernel.to_string/1) |> Enum.join(", ")
    "#{value(iterator)} <- [#{list_str}]"
  end

  defp step_count(%__MODULE__{} = iterator) do
    case iterator.count do
      :not_started -> 0
      :finished -> :finished
      count when count < length(iterator.list) - 1 -> count + 1
      _ -> :finished
    end
  end

  def reset(%__MODULE__{} = iterator) do
    %{iterator | count: :not_started}
  end

  def finish?(%__MODULE__{} = iterator) do
    iterator.count == :finished
  end
end
