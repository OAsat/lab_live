defmodule LabLive.MixProject do
  use Mix.Project

  def project do
    [
      app: :lab_live,
      version: "0.2.4",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex, :wx, :observer, :runtime_tools],
      mod: {LabLive.Application, []}
    ]
  end

  defp deps do
    [
      {:erlport, "~> 0.11.0"},
      {:telemetry, "~> 1.2"},
      {:jason, "~> 1.4"},
      {:toml, "~> 0.7.0"},
      {:kino, "~> 0.11.0"},
      {:kino_vega_lite, "~> 0.1.10"},
      {:ex_doc, "~> 0.30.8", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 0.5", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
