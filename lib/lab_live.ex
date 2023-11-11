defmodule LabLive do
  @moduledoc """
  Documentation for `LabLive`.
  """
  alias LabLive.Data

  @type on_start_data() :: {:ok, pid()} | {:override, pid()} | {:error, term()}
  @type many_data() :: %{Data.name() => Data.data_specs()} | [{Data.name(), Data.data_specs()}]

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

  @spec start_many_data(many_data(), module()) :: [{Data.name(), on_start_data()}]
  def start_many_data(many_data, supervisor \\ LabLive.Data.Supervisor) do
    for {name, data_specs} <- many_data do
      {name, start_data(name, data_specs, supervisor)}
    end
  end

  @spec start_data(Data.name(), Data.data_specs(), module()) :: on_start_data()
  def start_data(name, data_specs, supervisor \\ LabLive.Data.Supervisor) do
    case DynamicSupervisor.start_child(supervisor, {LabLive.Data, [{:name, name} | data_specs]}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        :ok = data_specs[:init] |> LabLive.Data.override(pid)
        {:override, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec data_to_markdown(many_data()) :: String.t()
  def data_to_markdown(many_data) do
    content =
      many_data
      |> Enum.filter(fn {_, specs} -> Keyword.get(specs, :visible?, true) end)
      |> Enum.map(fn {name, specs} ->
        "|#{name}|#{specs[:label]}|#{LabLive.Data.get(name)}|"
      end)
      |> Enum.join("\n")

    "|key|label|value|\n|--|--|--|\n" <> content <> "\n"
  end

  @spec render_data(many_data()) :: Kino.Markdown.t()
  def render_data(many_data) do
    data_to_markdown(many_data) |> Kino.Markdown.new()
  end
end
