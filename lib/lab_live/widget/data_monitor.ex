defmodule LabLive.Widget.DataMonitor do
  def data_to_markdown(many_data) do
    content =
      many_data
      |> Enum.filter(fn {_, specs} -> Keyword.get(specs, :visible?, true) end)
      |> Enum.map(fn {name, specs} ->
        value = LabLive.Data.get(name)

        value_str =
          case String.Chars.impl_for(value) do
            nil -> inspect(value)
            _ -> to_string(value)
          end

        "|#{name}|#{specs[:label]}|#{value_str}|"
      end)
      |> Enum.join("\n")

    "|key|label|value|\n|--|--|--|\n" <> content <> "\n"
  end

  def render_data(many_data) do
    data_to_markdown(many_data) |> Kino.Markdown.new()
  end

  def monitor_data(many_data, interval \\ 200) do
    Kino.animate(interval, fn _ -> render_data(many_data) end)
  end
end
