defmodule LabLive.Connection.Method.Dummy do
  alias LabLive.Connection.Method
  alias LabLive.Model
  alias LabLive.Model.Format

  @behaviour Method

  @type opt() :: {:model, any()}
  @type opts() :: [opt()]

  @impl Method
  def init(opts) do
    {opts[:model], opts[:random] || false}
  end

  @impl Method
  def read(_message, {nil, _}) do
    ""
  end

  def read(message, {%Model{} = model, random?}) do
    case message |> String.replace(model.character.input_term, "") |> find_key(model) do
      {_, %{output: output}} -> dummy_output(output, random?) <> model.character.output_term
      _ -> ""
    end
  end

  @impl Method
  def write(_message, _state) do
    :ok
  end

  @impl Method
  def terminate(_reason, _state) do
    :ok
  end

  defp find_key(query, model) do
    Enum.find(model.query, fn {_key, %{input: input}} ->
      Regex.match?(Format.format_to_regex(input), query)
    end)
  end

  defp dummy_output(output_format, random?) do
    params =
      for {key, type} <- Format.extract_keys_and_types(output_format) do
        {key, dummy_value(type, random?)}
      end

    Format.format(output_format, params)
  end

  defp dummy_value(:int, true), do: :rand.uniform(100)
  defp dummy_value(:int, false), do: 1
  defp dummy_value(:float, true), do: :rand.uniform()
  defp dummy_value(:float, false), do: 1.0
  defp dummy_value(:str, _), do: "dummy"
  defp dummy_value(nil, _), do: "dummy"
end
