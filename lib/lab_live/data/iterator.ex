defmodule LabLive.Data.Iterator do
  @moduledoc """
  Iterator for lists.

      iex> alias LabLive.Data.Iterator
      iex> iter = Iterator.new([5, 6, 7])
      iex> Iterator.value(iter)
      :not_started
      iex> iter = Iterator.step(iter)
      iex> Iterator.value(iter)
      5
      iex> Iterator.finish?(iter)
      false
      iex> iter = Iterator.step(iter)
      iex> Iterator.value(iter)
      6
      iex> Iterator.finish?(iter)
      false
      iex> iter = Iterator.step(iter)
      iex> Iterator.value(iter)
      7
      iex> Iterator.finish?(iter)
      false
      iex> iter = Iterator.step(iter)
      iex> Iterator.value(iter)
      :finished
      iex> Iterator.finish?(iter)
      true
      iex> iter = Iterator.step(iter)
      iex> Iterator.value(iter)
      :finished
      iex> Iterator.finish?(iter)
      true
      iex> iter = Iterator.reset(iter)
      iex> Iterator.value(iter)
      :not_started
  """
  defstruct [:count, :list]

  defimpl String.Chars do
    def to_string(iterator) do
      LabLive.Data.Iterator.to_string(iterator)
    end
  end

  alias LabLive.Data

  @type t() :: %__MODULE__{
          count: :not_started | non_neg_integer() | :finished,
          list: list()
        }

  def new(list) when is_list(list) do
    %__MODULE__{count: :not_started, list: list}
  end

  def value(key) when is_atom(key) do
    Data.get(key) |> value()
  end

  def value(%__MODULE__{} = iterator) do
    case iterator.count do
      :not_started -> :not_started
      :finished -> :finished
      count -> iterator.list |> Enum.at(count)
    end
  end

  def step(key) when is_atom(key) do
    Data.get(key) |> step() |> Data.update(key)
  end

  def step(%__MODULE__{} = iterator) do
    case iterator.count do
      :not_started ->
        %__MODULE__{iterator | count: 0}

      :finished ->
        iterator

      count ->
        next = if count + 1 >= length(iterator.list), do: :finished, else: count + 1
        %__MODULE__{iterator | count: next}
    end
  end

  def reset(key) when is_atom(key) do
    Data.get(key) |> reset() |> Data.update(key)
  end

  def reset(%__MODULE__{} = iterator) do
    %{iterator | count: :not_started}
  end

  def finish?(key) when is_atom(key) do
    Data.get(key) |> finish?()
  end

  def finish?(%__MODULE__{} = iterator) do
    iterator.count == :finished
  end

  @doc """
  to_string

      iex> iter = LabLive.Data.Iterator.new([1, 2, 3, 4])
      iex> LabLive.Data.Iterator.to_string(iter)
      "not_started <- [1, 2, 3, 4]"
      iex> iter |> LabLive.Data.Iterator.step() |> to_string()
      "1 <- [1, 2, 3, 4]"
  """
  def to_string(%__MODULE__{} = iterator) do
    list_str = iterator.list |> Enum.map(&Kernel.to_string/1) |> Enum.join(", ")
    "#{value(iterator)} <- [#{list_str}]"
  end
end
