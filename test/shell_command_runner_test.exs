defmodule PolyglotWatcher.ShellCommandRunnerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias PolyglotWatcher.ShellCommandRunner

  describe "run/1" do
    test "runs the shell command" do
      assert capture_io(fn ->
               assert {command_output, exit_code} =
                        ShellCommandRunner.run(["echo", "hello mother"])

               assert exit_code == 0
               assert command_output == "hello mother\n"
             end) == "hello mother\n"
    end
  end
end
