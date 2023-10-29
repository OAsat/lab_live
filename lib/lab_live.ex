defmodule LabLive do
  @moduledoc """
  Documentation for `LabLive`.
  """

  def run_many(module, functions) do
    for function <- functions do
      Task.async(module, function, [])
    end
    |> Task.await_many()
  end
end
