defmodule LabLive.MixProject do
  use Mix.Project

  def project do
    [
      app: :lab_live,
      version: "0.1.2",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:timex, "~> 3.7"},
      {:telemetry, "~> 1.2"},
      {:kino, "~> 0.11.0"},
      {:kino_vega_lite, "~> 0.1.10"},
      {:ex_doc, "~> 0.30.8", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 0.5", only: :test}
    ]
  end
end
