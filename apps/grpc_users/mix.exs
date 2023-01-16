defmodule Derailed.GRPC.Users.MixProject do
  use Mix.Project

  def project do
    [
      app: :grpc_users,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GrpcUsers.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_registry, "~> 1.3"},
      {:ex_hash_ring, "~> 6.0"},
      {:fastglobal, "~> 1.0"},
      {:jsonrs, "~> 0.2.1"},
      {:grpc_protos, in_umbrella: true},
      {:sessions, in_umbrella: true}
    ]
  end
end