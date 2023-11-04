defmodule LabLive.Data.Iterator do
  @moduledoc """
  Iterator for lists.

      iex> alias LabLive.Data.Iterator
      iex> iter = Iterator.new([5, 6, 7])
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
      true
      iex> iter = Iterator.step(iter)
      iex> Iterator.value(iter)
      7
      iex> iter = Iterator.reset(iter)
      iex> Iterator.value(iter)
      5

      iex> LabLive.Data.Iterator.new([1, 2, 3, 4]) |> to_string()
      "1 <- [1, 2, 3, 4]"
  """
  defstruct [:count, :list]

  defimpl String.Chars do
    def to_string(iterator) do
      LabLive.Data.Iterator.to_string(iterator)
    end
  end

  alias LabLive.Data

  @type t() :: %__MODULE__{
          count: non_neg_integer(),
          list: list()
        }

  def new(list) when is_list(list) do
    %__MODULE__{count: 0, list: list}
  end

  def value(key) when is_atom(key) do
    Data.get(key) |> value()
  end

  def value(%__MODULE__{} = iterator) do
    iterator.list |> Enum.at(iterator.count)
  end

  def step(key) when is_atom(key) do
    Data.get(key) |> step() |> Data.update(key)
  end

  def step(%__MODULE__{} = iterator) do
    if finish?(iterator) do
      iterator
    else
      %__MODULE__{iterator | count: iterator.count + 1}
    end
  end

  def reset(key) when is_atom(key) do
    Data.get(key) |> reset() |> Data.update(key)
  end

  def reset(%__MODULE__{} = iterator) do
    %{iterator | count: 0}
  end

  def finish?(key) when is_atom(key) do
    Data.get(key) |> finish?()
  end

  def finish?(%__MODULE__{} = iterator) do
    iterator.count + 1 >= length(iterator.list)
  end

  def to_string(%__MODULE__{} = iterator) do
    list_str = iterator.list |> Enum.map(&Kernel.to_string/1) |> Enum.join(", ")
    "#{iterator.list |> Enum.at(iterator.count)} <- [#{list_str}]"
  end
end
