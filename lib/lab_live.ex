defmodule LabLive do
  @moduledoc """
  Documentation for `LabLive`.
  """

  require Logger

  def run_many(module, functions) do
    for function <- functions do
      Task.async(module, function, [])
    end
    |> Task.await_many(:infinity)
  end

  def time_id() do
    Timex.now("Japan")
    |> Timex.format!("{YY}{0M}{0D}_{0h24}{0m}{0s}")
  end

  def config_log_file(file) do
    Logger.add_backend({LoggerFileBackend, :debug})
    Logger.configure_backend({LoggerFileBackend, :debug}, path: file)
    Logger.info("Start logging to #{file}")
  end
end
