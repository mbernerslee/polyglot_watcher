defmodule PolyglotWatcher do
  use Application
  alias PolyglotWatcher.Server
  alias PolyglotWatcher.Puts

  # TODO don't put stderror on the screen, as a way of fixnig this kinda thing?
  # Checking if there're any other test failures in that file   /[os_mon] cpu supervisor port (cpu_sup): Erlang has closed
  # [os_mon] memory supervisor port (memsup): Erlang has closed
  # Checking if there're any other test failures in that file   ✓   28 tests, 0 failures
  #
  # Running 'mix test --color --failed --max-failures 1'   |[os_mon] memory supervisor port (memsup): Erlang has closed
  # [os_mon] cpu supervisor port (cpu_sup): Erlang has closed
  # Running 'mix test --color --failed --max-failures 1'   ✓   There are no tests to run
  #
  # Running all tests   \warning: variable "ac" is unused (if the variable is not meant to be used, prefix it with an underscore)
  #  test/platform/subjects/subjects_test.exs:56: Platform.SubjectsTest."test all/0 does not yield duplicates when one subject exists in both GB and US"/1
  #
  # Running all tests   /[os_mon] memory supervisor port (memsup): Erlang has closed
  # [os_mon] cpu supervisor port (cpu_sup): Erlang has closed
  # Running all tests   ✓   4712 tests, 0 failures

  def start(_type \\ :normal, _args \\ []) do
    children = [Server.child_spec(), Puts.child_spec()]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
