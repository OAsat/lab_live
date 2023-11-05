defmodule LabLive.Execution.Diagram do
  @moduledoc """
  Diagram of execution.

  ### Example
  ```
  #{File.read!("test/support/sample_diagram.ex")}
  ```
  """

  @type diagram :: map()
  @type stage ::
          :start
          | :finish
          | {atom(), atom()}
          | [f: function(), str: String.t(), branch: map() | Keyword.t()]

  @doc """
  Converts a diagram to a string of mermaid diagram.

      iex> import LabLive.Execution.Diagram
      iex> to_mermaid(SampleDiagram.diagram)
  """
  def to_mermaid(diagram, opts \\ []) do
    running = opts[:running]

    head = [
      """
      flowchart TB
      classDef function fill:#fff5ad,stroke:#decc93
      classDef running fill:#f96,stroke:#f00
      """
    ]

    tail =
      for {key, value} <- diagram do
        key_str = to_text(running, nil, key)
        running? = if key == running, do: ":::running", else: ""
        "#{key_str}#{running?} --> #{to_text(running, key_str, value)}"
      end

    Enum.join([head | tail], "\n")
  end

  @doc """
  Converts a diagram to a string of mermaid diagram in markdown format.
  """
  def to_mermaid_markdown(map, opts \\ []) do
    """
    ```mermaid
    #{to_mermaid(map, opts)}
    ```
    """
    |> Kino.Markdown.new()
  end

  defp to_text(_running, _prefix, {module, function})
       when is_atom(module) and is_atom(function) do
    mod_str = to_string(module) |> String.replace("Elixir.", "")
    "#{mod_str}.#{function}"
  end

  defp to_text(running, _prefix, atom) when is_atom(atom) do
    finish? = if atom == running and running == :finish, do: ":::running", else: ""
    "#{atom}#{finish?}"
  end

  defp to_text(running, prefix, f: function, str: f_label, branch: branch)
       when is_function(function, 0) do
    head = "#{prefix}_f{{\"#{f_label}\"}}:::function"

    tail =
      for {key, value} <- branch do
        "#{prefix}_f --> |#{key}| #{to_text(running, "", value)}"
      end

    [head | tail] |> Enum.join("\n")
  end

  @spec run_step(diagram(), stage()) :: stage()
  def run_step(diagram, :start) do
    diagram[:start]
  end

  def run_step(_diagram, :finish) do
    :finish
  end

  def run_step(diagram, {module, function} = stage) when is_atom(module) and is_atom(function) do
    Kernel.apply(module, function, [])
    diagram[stage]
  end

  def run_step(_diagram, f: function, str: _, branch: branch)
      when is_function(function, 0) do
    branch[function.()]
  end
end
