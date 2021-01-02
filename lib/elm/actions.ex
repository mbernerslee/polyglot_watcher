defmodule PolyglotWatcher.Elm.Actions do
  alias PolyglotWatcher.ShellCommandRunner

  def run_action({:make, path}, server_state) do
    {mix_test_output, exit_code} = ShellCommandRunner.run(["elm", "make", path])
    {exit_code, server_state}
  end
end
