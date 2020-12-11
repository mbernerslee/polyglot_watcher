defmodule PolyglotWatcher do
  alias PolyglotWatcher.Server

  def main(_command_line_args \\ "") do
    run()
    :timer.sleep(:infinity)
  end

  defp run do
    children = [Server.child_spec()]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
