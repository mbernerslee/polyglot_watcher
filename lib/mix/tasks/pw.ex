defmodule Mix.Tasks.Pw do
  use Mix.Task
  alias PolyglotWatcher.Server

  @preferred_cli_env :test

  def run(_args) do
    Server.start_link()
    :timer.sleep(:infinity)
  end
end
