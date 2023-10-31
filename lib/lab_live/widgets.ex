defmodule LabLive.Widgets do
  alias LabLive.Variables

  def render_props(props) do
    content =
      for {key, opts} <- props do
        label = Keyword.get(opts, :label, to_string(key))
        "|#{key}|#{label}|#{Variables.get(key)}|"
      end
      |> Enum.join("\n")

    Kino.Markdown.new("|key|label|value|\n|--|--|--|\n" <> content)
  end

  def monitor_props(props, interval \\ 100) do
    Kino.animate(interval, fn _ -> render_props(props) end)
  end
end
