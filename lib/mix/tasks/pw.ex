defmodule Mix.Tasks.Pw do
  use Mix.Task
  alias PolyglotWatcher

  @preferred_cli_env :test

  def run(command_line_args \\ []) do
    PolyglotWatcher.main(command_line_args)
    :timer.sleep(:infinity)
  end
end
