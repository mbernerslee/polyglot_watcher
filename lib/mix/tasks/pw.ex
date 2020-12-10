defmodule Mix.Tasks.Pw do
  use Mix.Task
  alias PolyglotWatcher

  @preferred_cli_env :test

  def run(_args) do
    PolyglotWatcher.start()
    :timer.sleep(:infinity)
  end
end
