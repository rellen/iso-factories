# A Mix project only so the talk can render with Expresso. Nothing here is part of a factory
# page: the factories stay single files with no build step.
defmodule Line4Talk.MixProject do
  use Mix.Project

  def project do
    [
      app: :line4_talk,
      version: "0.1.0",
      elixir: "~> 1.20",
      deps: deps()
    ]
  end

  def application, do: []

  defp deps do
    [
      # Pinned to a commit, so the rendered talk changes only when this line does.
      {:expresso,
       github: "rellen/expresso",
       ref: "32a05dabd21a5923c99e85f7fd4a000980b7d2e0",
       only: :dev,
       runtime: false}
    ]
  end
end
