defmodule Labex.MixProject do
  use Mix.Project

  def project do
    [
      app: :labex,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex, :wx, :observer, :runtime_tools],
      mod: {Labex.Application, []}
    ]
  end

  defp deps do
    []
  end
end
