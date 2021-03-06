defmodule Classroom.MixProject do
  use Mix.Project

  def project do
    [
      app: :classroom,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Classroom, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.5"},
      {:poison, "~> 4.0"},
      {:gun, "~> 1.3"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:mongooseice, "~> 0.4.0"},
      {:cors_plug, "~> 2.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
