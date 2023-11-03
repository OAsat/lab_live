defmodule LabLive.Execution.Diagram do
  defmacro branch(exp, branch) do
    exp_str = quote(do: unquote(exp)) |> Macro.to_string()

    quote do
      [f: fn -> unquote(exp) end, str: unquote(exp_str), branch: unquote(branch)]
    end
  end

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
        key_str = to_text(nil, key)
        running? = if key == running, do: ":::running", else: ""
        "#{key_str}#{running?} --> #{to_text(key_str, value)}"
      end

    Enum.join([head | tail], "\n")
  end

  def to_mermaid_markdown(map, opts \\ []) do
    """
    ```mermaid
    #{to_mermaid(map, opts)}
    ```
    """
    |> Kino.Markdown.new()
  end

  defp to_text(_prefix, {module, function})
       when is_atom(module) and is_atom(function) do
    mod_str = to_string(module) |> String.replace("Elixir.", "")
    "#{mod_str}.#{function}"
  end

  defp to_text(_prefix, atom) when is_atom(atom) do
    "#{atom}"
  end

  defp to_text(prefix, f: function, str: f_label, branch: branch)
       when is_function(function, 0) do
    head = "#{prefix}_f{{\"#{f_label}\"}}:::function"

    tail =
      for {key, value} <- branch do
        "#{prefix}_f --> |#{key}| #{to_text("", value)}"
      end

    [head | tail] |> Enum.join("\n")
  end
end
