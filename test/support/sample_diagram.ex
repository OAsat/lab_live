defmodule SampleDiagram do
  import LabLive.Execution

  defmodule E do
    def hello, do: nil
    def goodbye, do: nil
  end

  defmodule S do
    def hola, do: nil
    def adios, do: nil
  end

  def eng?, do: true

  def diagram() do
    %{
      :start => branch(eng?(), true: {E, :hello}, false: {S, :hola}),
      {E, :hello} => {E, :goodbye},
      {S, :hola} => {S, :adios},
      {E, :goodbye} => :finish,
      {S, :adios} => :finish
    }
  end
end
