defmodule LabLive.Data.Loop do
  @moduledoc """
  Data structure to provide cyclic loop of a list.

      iex> loop = LabLive.Data.Loop.new([1, 2])
      iex> LabLive.Data.Loop.value(loop)
      1
      iex> loop = LabLive.Data.Loop.update(loop, nil)
      iex> LabLive.Data.Loop.value(loop)
      2
      iex> loop = LabLive.Data.Loop.update(loop, nil)
      iex> LabLive.Data.Loop.value(loop)
      1

      iex> loop = LabLive.Data.Loop.new([3, 4, 5])
      iex> LabLive.Data.Loop.to_string(loop)
      "3 <- [3, 4, 5]"
      iex> loop = LabLive.Data.Loop.update(loop, nil)
      iex> LabLive.Data.Loop.to_string(loop)
      "4 <- [3, 4, 5]"
  """
  defstruct [:count, :list]
  alias LabLive.Data
  @behaviour Data.Behaviour

  @impl Data.Behaviour
  def new(list) when is_list(list) do
    %__MODULE__{count: 0, list: list}
  end

  @impl Data.Behaviour
  def value(%__MODULE__{} = loop) do
    Enum.at(loop.list, rem(loop.count, length(loop.list)))
  end

  @impl Data.Behaviour
  def update(%__MODULE__{} = loop, nil) do
    %__MODULE__{loop | count: loop.count + 1}
  end

  @impl Data.Behaviour
  def to_string(%__MODULE__{} = loop) do
    list_str = loop.list |> Enum.map(&Kernel.to_string/1) |> Enum.join(", ")
    "#{value(loop)} <- [#{list_str}]"
  end

  def reset(%__MODULE__{} = loop) do
    %{loop | count: 0}
  end
end
