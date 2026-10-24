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
       ref: "ea89364c44d6a0917869551013c0eb26772e7cb9",
       only: :dev,
       runtime: false}
    ]
  end
end
