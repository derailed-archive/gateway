defmodule Derailed.MixProject do
  use Mix.Project

  def project do
    [
      app: :derailed,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Derailed, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fastglobal, "~> 1.0"},
      {:manifold, "~> 1.5"},
      {:mongodb_driver, "~> 1.0"},
      {:dotenvy, "~> 0.7"},
      {:joken, "~> 2.5"},
      {:jason, "~> 1.4"},
      {:gen_registry, "~> 1.3"},
      {:grpc, "~> 0.5"},
      {:protobuf, "~> 0.11"},
      {:hammer, "~> 6.1"},
      {:cowboy, "~> 2.9"},
      {:tesla, "~> 1.5"},
      {:hackney, "~> 1.17"},
      {:jsonrs, "~> 0.2.1"},
      {:patch, "~> 0.12.0", only: [:test]},
    ]
  end
end
