defmodule PolyglotWatcher.MixProject do
  use Mix.Project

  def project do
    [
      app: :polyglot_watcher,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: PolyglotWatcher]
    ]
  end

  #def application do
  #  [extra_applications: [:ex_ncurses]]
  #end

  defp elixirc_paths(:test) do
    ["lib", "test/builders"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end

  defp deps do
    [
      {:file_system, "~> 0.2"},
      {:ex_ncurses, "~> 0.3"}
    ]
  end
end
